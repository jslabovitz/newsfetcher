module NewsFetcher

  class Profile

    attr_reader   :dir
    attr_accessor :config

    include SetParams

    def initialize(params={})
      set(params)
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
      status = [status].flatten.compact if status
      sort ||= :id
      ids = all_ids if ids.nil? || ids.empty?
      ids.map do |id|
        dir = subscriptions_dir / id
        config = @config.load(dir / ConfigFileName)
        Subscription.new(id: id, dir: dir, config: config)
      end.
        reject { |s| s.config.disable }.
        select { |s| status.nil? || status.include?(s.status) }.
        sort_by { |s| s.send(sort).to_s }
    end

    def add_subscription(subscription, **options)
      subscription.dir = subscriptions_dir / subscription.id
      subscription.config.parent = @config
      raise Error, "Subscription already exists (as #{subscription.id})" if subscription.exist?
      subscription.save
      $logger.info { "Saved new subscription to #{subscription.id}" }
      subscription
    end

    def show(args, status: nil, sort: nil, details: false)
      status = [status].flatten.compact if status
      sort ||= :id
      find_subscriptions(ids: args, status: status, sort: sort).each do |subscription|
        subscription.print(format: details ? :list : :table)
      end
    end

    def update(args)
      threads = []
      find_subscriptions(ids: args).each do |subscription|
        if threads.length >= @config.max_threads
          $logger.debug { "Waiting for #{threads.length} threads to finish" }
          threads.map(&:join)
          threads = []
        end
        threads << Thread.new do
          $logger.debug { "Started thread for #{subscription.id}" }
          begin
            subscription.update
          rescue Error => e
            $logger.error { "#{subscription.id}: #{e}" }
          end
        end
      end
      $logger.debug { "Waiting for last #{threads.length} threads to finish" }
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

    def edit(args)
      find_subscriptions(ids: args).each do |subscription|
        subscription.edit
      end
    end

  end

end