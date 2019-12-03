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

    def self.init(dir, params)
      dir = Path.new(dir)
      raise Error, "#{dir} already exists" if dir.exist?
      profile = new({ dir: dir }.merge(params))
    end

    def initialize(params={})
      @max_threads = DefaultMaxThreads
      @style = StylesheetFile.read
      @delivery_method = [:sendmail]
      @mail_subject = '[%b] %t'
      @log_level = Logger::INFO
      params.each { |k, v| send("#{k}=", v) if v }
      raise Error, "dir not set" unless @dir
      @bundle = Bundle.new(@dir)
      @bundle.info.each { |k, v| send("#{k}=", v) }
      @logger = Logger.new(STDERR,
        level: @log_level,
        formatter: proc { |severity, datetime, progname, msg|
          "%s %5s: %s\n" % [datetime.strftime('%FT%T%:z'), severity, msg]
        },
      )
    end

    def save
      @bundle.info.mail_from = @mail_from
      @bundle.info.mail_to = @mail_to
      @bundle.save
    end

    def dir=(dir)
      @dir = Path.new(dir)
    end

    def delivery=(info)
      info = info.dup
      method = info.delete(:method) or raise Error, "No delivery method defined"
      @delivery_method = [method.to_sym, info]
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
      @logger.info { "#{item.subscription.id}: Sending #{item.title.inspect}" }
      mail = item.make_email
      mail.delivery_method(*@delivery_method)
      mail.deliver!
    end

    def find_subscriptions(ids: nil, status: nil, sort: nil)
      status ||= [:active, :dormant, :never]
      status = [status].flatten
      sort ||= :id
      Subscription.find(profile: self, ids: ids)
        .select { |s| status.include?(s.status) }
        .sort_by { |s| s.send(sort).to_s }
    end

    def add_subscription(uri:, path: nil)
      uri = Addressable::URI.parse(uri)
      NewsFetcher.verify_uri!(uri)
      key = Subscription.uri_to_key(uri)
      path = Path.new(path ? "#{path}/#{key}" : key)
      subscription = Subscription.new(dir: subscriptions_dir / path, link: uri, profile: self)
      raise Error, "Subscription already exists (as #{subscription.id}): #{uri}" if subscription.exist?
      subscription.save
      @logger.info { "Saved new subscription to #{subscription.id}" }
    end

    def discover_feed(uri)
      uri = Addressable::URI.parse(uri)
      NewsFetcher.verify_uri!(uri)
      response = NewsFetcher.get(uri)
      case response[:status]
      when :loaded
        html = Nokogiri::HTML::Document.parse(response[:content])
        html.xpath('//link[@rel="alternate"]').each do |link|
          puts "%s (%s)" % [link['title'], link['type']]
          puts uri.join(Addressable::URI.parse(link['href']))
          puts
        end
      when :failed
        raise Error, "Failed to load: #{response[:message]}"
      else
        raise Error, "Unknown response: #{response.inspect}"
      end
    end

    def list(args, status: nil, sort: nil, details: false)
      status ||= [:active, :dormant, :never]
      status = [status] unless status.kind_of?(Array)
      sort ||= :id
      find_subscriptions(ids: args, status: status, sort: sort).each do |subscription|
        if details
          subscription.list_details
        else
          subscription.list_summary
        end
      end
    end

    def update(args)
      threads = []
      find_subscriptions(ids: args).each do |subscription|
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
      find_subscriptions(ids: args).each do |subscription|
        subscription.reset
      end
    end

    def fix(args)
      find_subscriptions(ids: args).each do |subscription|
        subscription.fix
      end
    end

    def remove(args)
      find_subscriptions(ids: args).each do |subscription|
        subscription.remove
      end
    end

    def show(args, keys: nil)
      find_subscriptions(ids: args).each do |subscription|
        subscription.show(keys)
      end
    end

    def show_message(args)
      find_subscriptions(ids: args).each do |subscription|
        subscription.show_message
      end
    end

  end

end