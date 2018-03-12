module Feeder

  class Profile

    attr_accessor :dir
    attr_accessor :email
    attr_accessor :mail_dir

    def initialize(name:)
      ##FIXME: configure all below
      @dir = Path.new('~/.feeds').expand_path / name
      @email = "jlabovitz+News@fastmail.fm"
      @mail_dir = Path.new('~/Mail/jlabovitz/News')
    end

    DefaultSubscriptionsFileSubscriptionsFile = '~/Library/Application Support/NetNewsWire/Subscriptions.plist'

    def import(args, options)
      plist_file = Path.new(args.shift || DefaultSubscriptionsFile).expand_path
      read_plist_file(plist_file) do |item, path|
        key = Feeder.uri_to_key(item['rss'])
        puts "importing %-60s => %s" % [item['rss'], key]
        subscription = Subscription.new(
          id: path.join('/'),
          title: item['name'],
          feed_link: item['rss'])
        raise "Subscription exists: #{subscription.info_file}" if subscription.info_file.exist?
        subscription.save
      end
    end

    def add(args, options)
      feed_link, path = *args
      response = get(feed_link)
      raise Error, "Failed to get URI #{feed_link}: #{response.status}" unless response.success?
      if response.body !~ /^<?xml/
        # find link
      end
      subscription = Subscription.new(
        id: id,
        title: feed.title,
        feed_link: feed_link)
      subscription.save
    end

    def update(args, options)
      if args.empty?
        info_files = @dir.glob("**/*.yaml")
      else
        info_files = args.map { |a| Path.new(a) }
      end
      threads = []
      info_files.each do |info_file|
        raise "Subscription info file does not exist: #{info_file}" unless info_file.exist?
        subscription = Subscription.load(info_file: info_file, profile: self)
        threads << Thread.new do
          begin
            subscription.update(options)
          rescue Error => e
            warn "#{subscription.id}: #{e}"
            Thread.exit
          end
        end
      end
      threads.map(&:join)
    end

    private

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