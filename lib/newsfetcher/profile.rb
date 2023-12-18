module NewsFetcher

  class Profile

    attr_reader   :dir
    attr_accessor :config

    include SetParams

    def initialize(params={})
      super
      setup_logger
      setup_styles
    end

    def setup_logger
      $logger = Logger.new(STDERR,
        level: @config.log_level,
        formatter: proc { |severity, timestamp, progname, msg|
          "%s %5s: %s\n" % [timestamp.strftime('%FT%T%:z'), severity, msg]
        },
      )
    end

    def setup_styles
      raise Error, "dir not set" unless @dir
      @styles = [@config.main_stylesheet, @config.aux_stylesheets].flatten.compact.map do |file|
        file = Path.new(file)
        file = @dir / file if file.relative?
        SassC::Engine.new(file.read, syntax: :scss, style: :compressed).render
      end
    end

    def dir=(dir)
      @dir = Path.new(dir).expand_path
    end

    def id
      @dir.basename.to_s
    end

    def config_file
      @dir / ConfigFileName
    end

    def subscriptions_dir
      @dir / SubscriptionsDirName
    end

    def all_ids
      subscriptions_dir.glob("**/#{ConfigFileName}").map { |p| p.dirname.relative_to(subscriptions_dir).to_s }
    end

    def find_subscriptions(ids: nil, status: nil, sort: nil)
      status = [status].flatten.compact if status
      sort ||= :id
      ids = all_ids if ids.nil? || ids.empty?
      subscriptions = ids.map do |id|
        subscription_dir = subscriptions_dir / id
        begin
          subscription_config = @config.load(subscription_dir / ConfigFileName)
        rescue Config::Error => e
          raise "#{id}: #{e}"
        end
        Subscription.new(id: id, dir: subscription_dir, config: subscription_config, styles: @styles)
      end
      subscriptions.
        reject { |s| s.config.disabled }.
        select { |s| status.nil? || status.include?(s.status) }.
        sort_by { |s| s.send(sort).to_s }
    end

    def add_subscription(uri:, id: nil, path: nil)
      uri = Addressable::URI.parse(uri)
      raise Error, "Bad URI: #{uri}" unless uri.absolute?
      id ||= uri.make_subscription_id
      id = "#{path}/#{id}" if path
      subscription_dir = subscriptions_dir / id
      raise Error, "Subscription already exists in #{subscription_dir}" if subscription_dir.exist?
      subscription_dir.mkpath
      config = @config.make(uri: uri)
      config_file = subscription_dir / ConfigFileName
      config.save(config_file)
      $logger.info { "Saved new subscription to #{config_file}" }
      subscription_dir
    end

  end

end