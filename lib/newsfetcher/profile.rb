module NewsFetcher

  class Profile

    attr_accessor :dir
    attr_accessor :mail_from
    attr_accessor :mail_to
    attr_accessor :mail_subject
    attr_accessor :max_threads
    attr_accessor :style
    attr_accessor :logger
    attr_accessor :log_level

    def self.load(dir, params={})
      new(
        {
          dir: dir,
          style: StylesheetFile.read,
        }.merge(NewsFetcher.load_yaml(dir / InfoFileName)).merge(params)
      )
    end

    def initialize(params={})
      @max_threads = DefaultMaxThreads
      @delivery_method = [:sendmail]
      @mail_subject = '[%i] %t'
      @log_level = Logger::INFO
      params.each { |k, v| send("#{k}=", v) if v }
      @logger = Logger.new(STDERR,
        level: @log_level,
        formatter: NewsFetcher.method(:log_formatter).to_proc)
    end

    def dir=(dir)
      @dir = Path.new(dir)
    end

    def mailer=(location)
      @delivery_method = [:sendmail, location: location]
    end

    def mail_from=(address)
      @mail_from = Mail::Address.new(address)
    end

    def mail_to=(address)
      @mail_to = Mail::Address.new(address)
    end

    def id
      @dir.basename.to_s
    end

    def subscriptions_dir
      @dir / SubscriptionsDirName
    end

    def send_item(item)
      mail = item.make_email
      @logger.info { "#{item.subscription.id}: Sending #{mail.subject.inspect}" }
      mail.delivery_method(*@delivery_method)
      mail.deliver!
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
      @logger.info { "Saved new subscription to #{subscription.id}" }
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

    def update(args)
      threads = []
      subscriptions(args).each do |subscription|
        if threads.length >= @max_threads
          @logger.debug { "Waiting for #{threads.length} threads to finish" }
          threads.map(&:join)
          threads = []
        end
        threads << Thread.new do
          @logger.debug { "Started thread for #{subscription.id}" }
          begin
            subscription.update_feed
            subscription.process do |item|
              send_item(item)
            end
          rescue Error => e
            @logger.error { "#{subscription.id}: #{e}" }
          end
        end
      end
      @logger.debug { "Waiting for last #{threads.length} threads to finish" }
      threads.map(&:join)
    end

    def reset(args)
      subscriptions(args).each do |subscription|
        subscription.reset
      end
    end

    def fix(args)
      subscriptions(args).each do |subscription|
        subscription.fix
      end
    end

    def remove(args)
      subscriptions(args).each do |subscription|
        subscription.remove
      end
    end

    def show(args, keys: nil)
      subscriptions(args).each do |subscription|
        subscription.show(keys)
      end
    end

    def show_message(args)
      subscriptions(args).each do |subscription|
        subscription.show_message
      end
    end

  end

end