module Feeder

  class Profile

    attr_accessor :dir

    def initialize(name:)
      @dir = Feeder.subscriptions_dir / name
    end

    def import(args, options)
      plist_file = Path.new(args.shift || Feeder::SubscriptionsFile).expand_path
      read_plist_file(plist_file) do |item, path|
        dir = @dir
        key = Feeder.uri_to_key(item['rss'])
        ;;puts "importing %-60s => %s" % [item['rss'], key]
        (path + [key]).each { |p| dir /= p }
        raise "Subscription directory exists: #{dir}" if dir.exist?
        subscription = Subscription.new(
          title: item['name'],
          feed_link: item['rss'],
          dir: dir)
        subscription.save
      end
    end

    def list(args, options)
      each_subscription(:list, options, args)
    end

    def update(args, options)
      each_subscription(:update, options, args)
    end

    def process(args, options)
      each_subscription(:process, options, args)
    end

    def each_subscription(method, options, ids=nil)
      subscriptions = load_subscriptions
      selected_subscriptions = (ids.nil? || ids.empty?) ? subscriptions.values : ids.map { |id| subscriptions[id] }
      selected_subscriptions.each do |subscription|
        begin
          subscription.send(method, options)
        rescue Error => e
          warn "#{subscription.id}: #{e}"
        end
      end
    end

    private

    def load_subscriptions
      subscriptions = {}
      Feeder.subscriptions_dir.glob("**/#{Feeder::InfoFile}").each do |file|
        subscription = Subscription.load(dir: file.dirname, profile: self)
        subscriptions[subscription.id] = subscription
      end
      subscriptions
    end

    def read_plist_file(file, &block)
      io = IO.popen(['plutil', '-convert', 'xml1', '-o', '-', file.to_s], 'r')
      plist = Nokogiri::PList(io)
      recurse_plist(plist, &block)
    end

    def recurse_plist(items, path=[], &block)
      items.each do |item|
        if item['isContainer']
          recurse_plist(item['childrenArray'], path + [item['name']], &block)
        else
          yield(item, path)
        end
      end
    end

  end

end