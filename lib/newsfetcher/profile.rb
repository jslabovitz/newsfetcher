module NewsFetcher

  class Profile

    attr_accessor :root_dir
    attr_accessor :maildir
    attr_accessor :folder
    attr_accessor :email

    def self.load(dir)
      info_file = dir / InfoFileName
      new(YAML.load(info_file.read).merge(root_dir: dir))
    end

    def initialize(params={})
      params.each { |k, v| send("#{k}=", v) }
    end

    def root_dir=(dir)
      @root_dir = Path.new(dir)
    end

    def maildir=(dir)
      @maildir = Path.new(dir)
    end

    def email=(address)
      @email = Mail::Address.new(address)
    end

    def to_yaml
      {
        email: @email.to_s,
        maildir: @maildir.to_s,
        folder: @folder,
      }.to_yaml(line_width: -1)
    end

    def subscriptions_dir
      @root_dir / 'feeds'
    end

    def maildir_for_subscription(subscription)
      elems = [
        @maildir,
        @folder,
        subscription.relative_dir.dirname,
      ]
      Maildir.new(Path.new(*elems).to_s)
    end

    def mail_address_for_subscription(subscription, title)
      Mail::Address.new.tap do |a|
        a.display_name = title
        a.address = "%s+%s@%s" % [
          @email.local,
          [@folder, *subscription.relative_dir.each_filename.to_a].join('.'),
          @email.domain,
        ]
      end
    end

    def send_item(item, subscription)
      maildir = maildir_for_subscription(subscription)
      ;;warn "#{subscription.id}: #{item[:title].inspect} => #{maildir.path}"
      mail = Mail.new.tap do |m|
        m.date =         item[:date],
        m.from = m.to =  mail_address_for_subscription(subscription, item[:title])
        m.subject =      item[:title]
        m.content_type = 'text/html; charset=UTF-8'
        m.body         = ERB.new(message_template).result_with_hash(item)
      end
      maildir.add(mail)
    end

    def style
      @style ||= NewsFetcher::StylesheetFile.read
    end

    def message_template
      @message_template ||= MessageTemplateFile.read
    end

    def load_subscription(dir)
      Subscription.load(profile: self, path: dir.relative_to(subscriptions_dir))
    end

    def subscriptions(args=[])
      if args.empty?
        dirs = subscriptions_dir.glob("**/#{InfoFileName}").map(&:dirname)
      else
        dirs = args.map { |a| (a =~ %r{^[/~]}) ? Path.new(a) : (subscriptions_dir / a) }
      end
      dirs.map do |dir|
        Subscription.load(profile: self, dir: dir)
      end
    end

    def subscribe(uri:, path: nil)
      uri = URI.parse(uri)
      response = NewsFetcher.get(uri)
      raise Error, "Failed to get URI #{uri}: #{response.status}" unless response.success?
      begin
        Feedjira::Feed.parse(response.body)
      rescue Feedjira::NoParserAvailable => e
        new_uri = discover_feed(response.body)
        uri = new_uri.scheme ? new_uri : (uri + new_uri)
      end
      key = NewsFetcher.uri_to_key(uri)
      path = Path.new(path ? "#{path}/#{key}" : key)
      #FIXME: save feed data
      subscription = Subscription.new(dir: dir, link: uri, profile: self)
      raise Error, "Subscription already exists (as #{subscription.id}): #{uri}" if subscription.exist?
      subscription.save
      ;;warn "saved new subscription to #{subscription.id}"
    end

    def discover_feed(html_str)
      links = find_alternate_links(html_str)
      raise Error, "No alternate links" if links.empty?
      puts "Alternate links:"
      links.each_with_index do |link, i|
        puts "%2d. %s (%s): %s" % [i + 1, link[:href], link[:type], link[:title]]
      end
      loop do
        print "Choice? "
        i = gets.chomp.to_i
        return links[i - 1][:href] if i >= 1 && i <= links.length
      end
    end

    def find_alternate_links(html_str)
      html = Nokogiri::HTML::Document.parse(html_str)
      html.xpath('//link[@rel="alternate"]').map do |link_elem|
        {
          href: URI.parse(link_elem['href']),
          type: link_elem['type'],
          title: link_elem['title'],
        }
      end
    end

    def dormancy_report(args, period: nil)
      Hash[
        subscriptions(args).map do |subscription|
          [subscription.id, subscription.dormant_days]
        end
      ].reject { |k, v| v && v < period }.sort_by { |k, v| v || 0 }.reverse
    end

  end

end