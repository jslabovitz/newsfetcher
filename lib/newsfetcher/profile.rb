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
      @styles = [@config.main_stylesheet, @config.aux_stylesheets].compact.map do |file|
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
      subscriptions = ids.map do |id|
        dir = subscriptions_dir / id
        Subscription.new(
          id: id,
          dir: dir,
          config: @config.load(dir / ConfigFileName),
          styles: @styles)
      end
      subscriptions.
        reject { |s| s.config.disable }.
        select { |s| status.nil? || status.include?(s.status) }.
        sort_by { |s| s.send(sort).to_s }
    end

    def add_subscription(uri:, id: nil, path: nil)
      id = Subscription.make_id(uri) unless id
      id = "#{path}/#{id}" if path
      subscription = Subscription.new(
        id: id,
        dir: subscriptions_dir / id,
        config: @config.make(uri: uri),
        styles: @styles)
      raise Error, "Subscription already exists (as #{subscription.id})" if subscription.exist?
      subscription.save
      $logger.info { "Saved new subscription to #{subscription.id}" }
      subscription
    end

    def update_subscription(subscription)
      subscription.update
    end

  end

end