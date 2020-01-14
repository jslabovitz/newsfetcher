module NewsFetcher

  class Profile

    attr_accessor :dir
    attr_accessor :mail_from
    attr_accessor :mail_to
    attr_accessor :mail_subject
    attr_accessor :max_threads
    attr_accessor :stylesheets
    attr_accessor :styles
    attr_accessor :logger
    attr_accessor :log_level

    def self.init(dir, params)
      dir = Path.new(dir)
      raise Error, "#{dir} already exists" if dir.exist?
      profile = new({ dir: dir }.merge(params))
    end

    def initialize(params={})
      @max_threads = DefaultMaxThreads
      @delivery_method = [:sendmail]
      @mail_subject = '[%b] %t'
      @log_level = Logger::INFO
      @stylesheets = []
      params.each { |k, v| send("#{k}=", v) if v }
      read_info
      setup_logger
      setup_styles
    end

    def read_info
      raise Error, "dir not set" unless @dir
      @bundle = Bundle.new(@dir)
      @bundle.info.each { |k, v| send("#{k}=", v) }
    end

    def setup_logger
      @logger = Logger.new(STDERR,
        level: @log_level,
        formatter: proc { |severity, datetime, progname, msg|
          "%s %5s: %s\n" % [datetime.strftime('%FT%T%:z'), severity, msg]
        },
      )
    end

    def setup_styles
      @stylesheets << StylesheetFile
      @styles = @stylesheets.map do |file|
        file = @dir / file if file.relative?
        SassC::Engine.new(file.read, syntax: :scss, style: :compressed).render
      end
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

    def stylesheets=(files)
      @stylesheets = files.map { |f| Path.new(f) }
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

    def make_outline(ids)
      #FIXME: only handles one-level outline
      outline = {}
      find_subscriptions(ids: ids).each do |subscription|
        subpaths = subscription.id.split('/')
        subpaths.pop
        raise Error, "Multilevel OPML not supported: #{subpaths.inspect}" if subpaths.length > 1
        outline[subpaths.first] ||= []
        outline[subpaths.first] << subscription
      end
      outline
    end

    def find_subscriptions(ids: nil, status: nil, sort: nil)
      status ||= [:active, :dormant, :never]
      status = [status].flatten
      sort ||= :id
      subscriptions = Bundle.bundles(dir: subscriptions_dir, ids: ids).map do |bundle|
        Subscription.new(bundle.info.merge(profile: self, dir: bundle.dir))
      end
      subscriptions
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
      begin
        response = NewsFetcher.get(uri)
      rescue Error => e
        raise Error, "Failed to get #{@link}: #{e}"
      end
      html = Nokogiri::HTML::Document.parse(response[:content])
      html.xpath('//link[@rel="alternate"]').each do |link|
        puts link['title'] unless link['title'].to_s.empty?
        puts uri.join(Addressable::URI.parse(link['href']))
        puts link['type']
        puts
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

    def export(args)
      opml = Nokogiri::XML::Builder.new do |xml|
        xml.opml(version: '1.1') do
          xml.head do
            xml.title('Subscriptions')
          end
          xml.body do
            node_to_opml(make_outline(args), xml)
          end
        end
      end.doc
      print opml
    end

    def node_to_opml(node, xml)
      node.each do |folder, subscriptions|
        xml.outline(text: folder) do
          subscriptions.each do |subscription|
            feed = subscription.parse_feed
            xml.outline(
              type: 'rss',
              version: 'RSS',
              text: feed.title,
              title: feed.title,
              xmlUrl: subscription.link)
          end
        end
      end
    end

  end

end