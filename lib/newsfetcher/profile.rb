module NewsFetcher

  class Profile

    attr_accessor :dir
    attr_accessor :maildir
    attr_accessor :folder
    attr_accessor :email_from
    attr_accessor :email_to
    attr_accessor :coalesce
    attr_accessor :use_plus_addressing
    attr_accessor :max_threads

    def self.load(dir)
      new(
        {
          dir: dir,
        }.merge(NewsFetcher.load_yaml(dir / InfoFileName))
      )
    end

    def initialize(params={})
      @coalesce = false
      @use_plus_addressing = false
      @max_threads = DefaultMaxThreads
      params.each { |k, v| send("#{k}=", v) }
    end

    def dir=(dir)
      @dir = Path.new(dir)
    end

    def maildir=(dir)
      @maildir = Path.new(dir)
    end

    def email_from=(address)
      @email_from = Mail::Address.new(address)
    end

    def email_to=(address)
      @email_to = Mail::Address.new(address)
    end

    def coalesce=(state)
      @coalesce = !!state
    end

    def use_plus_addressing=(state)
      @use_plus_addressing = !!state
    end

    def to_yaml
      {
        email_from: @email_from.to_s,
        email_to: @email_to.to_s,
        maildir: @maildir.to_s,
        folder: @folder,
        coalesce: @coalesce,
        use_plus_addressing: @use_plus_addressing,
      }.to_yaml(line_width: -1)
    end

    def id
      @dir.basename.to_s
    end

    def subscriptions_dir
      @dir / SubscriptionsDirName
    end

    def mail_address_for_subscription(subscription)
      address = Mail::Address.new
      if @use_plus_addressing
        address.address = "%s+%s@%s" % [
          @email_to.local,
          [@folder, *subscription.relative_dir.each_filename.to_a].join('.'),
          @email_to.domain,
        ]
      else
        address.address = @email_to.address
      end
      address
    end

    def send_item(item, subscription)
      maildir_folder = @maildir / @folder / subscription.relative_dir
      maildir_folder = maildir_folder.dirname if @coalesce
      maildir = Maildir.new(maildir_folder.to_s)
      mail = Mail.new
      mail.date =         item[:date]
      mail.from =         @email_from
      mail.to =           mail_address_for_subscription(subscription)
      mail.subject =      "[%s] %s" % [subscription.id, item[:title]]
      mail.content_type = 'text/html; charset=UTF-8'
      mail.body         = ERB.new(message_template).result_with_hash(item)
      ;;warn "#{mail.subject.inspect} => #{maildir.path}"
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

    def add_subscription(uri:, path: nil)
      uri = URI.parse(uri)
      key = NewsFetcher.uri_to_key(uri)
      path = Path.new(path ? "#{path}/#{key}" : key)
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

    def list(args, status: nil, sort: nil)
      status ||= [:active, :dormant, :never]
      status = [status] unless status.kind_of?(Array)
      sort ||= :id
      subscriptions(args).select { |s| status.include?(s.status) }.sort_by { |s| s.send(sort).to_s }.each do |subscription|
        if (t = subscription.latest_item_timestamp)
          days = (Date.today - t.to_date).to_i
        else
          days = nil
        end
        puts "%8s | %10s | %-40.40s | %-40.40s" % [
          subscription.status,
          days ? "#{days} days" : 'never',
          subscription.title,
          subscription.id,
        ]
      end
    end

    def update_subscriptions(args)
      threads = []
      subscriptions(args).each do |subscription|
        if threads.length >= @max_threads
          # ;;warn "waiting for #{threads.length} threads to finish"
          threads.map(&:join)
          threads = []
        end
        threads << Thread.new do
          # ;;warn "started thread for #{subscription.id}"
          begin
            subscription.update_feed
            subscription.process
          rescue Error => e
            warn "#{subscription.id}: #{e}"
          end
        end
      end
      # ;;warn "waiting for last #{threads.length} threads to finish"
      threads.map(&:join)
    end

    def reset_subscriptions(args)
      subscriptions(args).each do |subscription|
        subscription.reset
      end
    end

    def fix_subscriptions(args)
      subscriptions(args).each do |subscription|
        subscription.fix
      end
    end

    def remove_subscriptions(args)
      subscriptions(args).each do |subscription|
        subscription.remove
      end
    end

  end

end