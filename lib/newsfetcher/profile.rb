module NewsFetcher

  class Profile

    attr_accessor :dir
    attr_accessor :maildir
    attr_accessor :folder
    attr_accessor :email

    def self.load(dir)
      dir = Path.new(dir).expand_path
      info_file = dir / InfoFileName
      raise Error, "Profile does not exist at #{dir}" unless dir.exist? && info_file.exist?
      new(YAML.load(info_file.read).merge(dir: dir))
    end

    def initialize(params={})
      params.each { |k, v| send("#{k}=", v) }
    end

    def dir=(dir)
      @dir = Path.new(dir)
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

    def id
      @dir.basename.to_s
    end

    def subscriptions_dir
      @dir / SubscriptionsDirName
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
      @style ||= StylesheetFile.read
    end

    def message_template
      @message_template ||= MessageTemplateFile.read
    end

    def subscriptions(args=[])
      if args.empty?
        dirs = subscriptions_dir.glob("**/#{InfoFileName}").map(&:dirname)
      else
        dirs = args.map { |a| (a =~ %r{^[/~.]}) ? Path.new(a) : (subscriptions_dir / a) }
      end
      dirs.map do |dir|
        Subscription.load(profile: self, dir: dir)
      end
    end

    def subscribe(uri:, path: nil)
      uri = URI.parse(uri)
      response = NewsFetcher.get(uri)
      begin
        Feedjira::Feed.parse(response.body)
      rescue Feedjira::NoParserAvailable
        raise Error, "URI is not a feed"
      end
      key = NewsFetcher.uri_to_key(uri)
      path = Path.new(path ? "#{path}/#{key}" : key)
      #FIXME: save feed data
      subscription = Subscription.new(dir: subscriptions_dir / path, link: uri, profile: self)
      raise Error, "Subscription already exists (as #{subscription.id}): #{uri}" if subscription.exist?
      subscription.save
      ;;warn "saved new subscription to #{subscription.id}"
    end

    def discover_feed(uri)
      response = NewsFetcher.get(uri)
      uri = URI.parse(uri)
      html = Nokogiri::HTML::Document.parse(response.body)
      html.xpath('//link[@rel="alternate"]').each do |link|
        href = uri.merge(URI.parse(link['href']))
        puts "%s (%s) %p" % [
          href,
          link['type'],
          link['title'],
        ]
      end
    end

    def dormancy_report(args, period: nil)
      Hash[
        subscriptions(args).map do |subscription|
          [subscription.id, subscription.dormant_days]
        end
      ].reject { |k, v| v && v < period }.sort_by { |k, v| v || 0 }.reverse
    end

    def update(args, max_threads: nil, ignore_history: false, limit: nil)
      update_subscriptions(args, max_threads: max_threads)
      subscriptions(args).each do |subscription|
        begin
          subscription.process(ignore_history: ignore_history, limit: limit)
        rescue Error => e
          warn "#{subscription.id}: #{e}"
        end
      end
    end

    def update_subscriptions(args, max_threads: nil)
      max_threads ||= 100
      threads = []
      subscriptions(args).each do |subscription|
        if threads.length >= max_threads
          # ;;warn "waiting for #{threads.length} threads to finish"
          threads.map(&:join)
          threads = []
        end
        threads << Thread.new do
          # ;;warn "started thread for #{subscription.id}"
          begin
            subscription.update_feed
          rescue Error => e
            warn "#{subscription.id}: #{e}"
          end
        end
      end
      # ;;warn "waiting for last #{threads.length} threads to finish"
      threads.map(&:join)
    end

    def process_subscriptions(args, ignore_history: nil, limit: nil)
      subscriptions(args).each do |subscription|
        begin
          subscription.process(ignore_history: ignore_history, limit: limit)
        rescue Error => e
          warn "#{subscription.id}: #{e}"
        end
      end
    end

    def fix_subscriptions(args)
      subscriptions(args).each do |subscription|
        subscription.fix
      end
    end

  end

end