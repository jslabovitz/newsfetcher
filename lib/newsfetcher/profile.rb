module NewsFetcher

  class Profile

    attr_reader   :dir
    attr_accessor :config

    include SetParams

    def initialize(params={})
      super
      setup_logger
    end

    def setup_logger
      $logger = Logger.new(STDERR,
        level: @config.log_level,
        formatter: proc { |severity, timestamp, progname, msg|
          "%s %5s: %s\n" % [timestamp.strftime('%FT%T%:z'), severity, msg]
        },
      )
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

    def save
      @config.save(config_file)
    end

    def all_ids
      subscriptions_dir.glob("**/#{ConfigFileName}").map { |p| p.dirname.relative_to(subscriptions_dir).to_s }
    end

    def find_subscriptions(ids: nil, status: nil, sort: nil)
      status = [status].flatten.compact if status
      sort ||= :id
      ids = all_ids if ids.nil? || ids.empty?
      ids.map do |id|
        dir = subscriptions_dir / id
        config = @config.load(dir / ConfigFileName)
        klass = SubscriptionClassForType[config.type || 'feed']
        klass.new(id: id, dir: dir, config: config)
      end.
        reject { |s| s.config.disable }.
        select { |s| status.nil? || status.include?(s.status) }.
        sort_by { |s| s.send(sort).to_s }
    end

    def add_subscription(subscription)
      subscription.dir = subscriptions_dir / subscription.id
      subscription.config.parent = @config
      subscription.config.type = subscription.class.type
      raise Error, "Subscription already exists (as #{subscription.id})" if subscription.exist?
      subscription.save
      $logger.info { "Saved new subscription to #{subscription.id}" }
      subscription
    end

  end

end