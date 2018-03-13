module Feeder

  class Profile

    attr_accessor :root_dir
    attr_accessor :feeds_dir
    attr_accessor :email
    attr_accessor :maildir

    def self.load(dir)
      info_file = dir / 'info.yaml'
      new(YAML.load(info_file.read).merge(root_dir: dir))
    end

    def initialize(params={})
      params.each { |k, v| send("#{k}=", v) }
    end

    def to_yaml
      {
        email: @email,
        maildir: @maildir,
      }.to_yaml(line_width: -1)
    end

    def feeds_dir
      @root_dir / 'feeds'
    end

    def info_files(args)
      if args.empty?
        feeds_dir.glob("**/*.yaml")
      else
        args.map do |arg|
          if arg =~ /\.yaml$/
            Path.new(arg)
          else
            (feeds_dir / arg).add_extension('.yaml')
          end
        end
      end
    end

    def each_subscription(args, &block)
      info_files(args).each do |info_file|
        subscription = Subscription.load(info_file: info_file, profile: self)
        begin
          yield(subscription)
        rescue Error => e
          raise Error, "#{subscription.id}: #{e}"
        end
      end
    end

    def import(args, options)
      plist_file = args.shift or raise Error, "Must specify plist file"
      io = IO.popen(['plutil', '-convert', 'xml1', '-o', '-', plist_file], 'r')
      plist = Nokogiri::PList(io)
      recurse_plist(plist) do |item, path|
        key = Feeder.uri_to_key(item['rss'])
        puts "importing %-60s => %s" % [item['rss'], key]
        subscription = Subscription.new(
          id: [path, key].join('/'),
          feed_link: item['rss'],
          profile: self)
        raise "Subscription exists: #{subscription.info_file}" if subscription.info_file.exist?
        subscription.save
        ;;warn "saved new subscription to #{subscription.info_file}"
      end
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

    def add(args, options)
      feed_link, path = *args
      feed_link = URI.parse(feed_link)
      response = Feeder.get(feed_link)
      raise Error, "Failed to get URI #{feed_link}: #{response.status}" unless response.success?
      begin
        feed = Feedjira::Feed.parse(response.body)
      rescue Feedjira::NoParserAvailable => e
        html = Nokogiri::HTML::Document.parse(response.body)
        link_elems = html.xpath('//link[@rel="alternate"]')
        raise Error, "No alternate links in URI: #{feed_link}" if link_elems.empty?
        link_elems.each do |link_elem|
          puts "%s (%s): %s" % [
            link_elem['title'] || '-',
            link_elem['type'],
            feed_link + URI.parse(link_elem['href'])
          ]
        end
        return
      end
      id = [path, Feeder.uri_to_key(feed_link)].compact.join('/')
      subscription = Subscription.new(
        id: id,
        feed_link: feed_link,
        profile: self)
      subscription.save
      ;;warn "saved new subscription to #{subscription.info_file}"
    end

    def update(args, options)
      threads = []
      each_subscription(args) do |subscription|
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

    def fix(args, options)
      each_subscription(args) do |subscription|
        subscription.fix(options)
        subscription.save
      end
    end

    DormantPeriod = 90    ##FIXME: configure in profile/subscription

    def dormant(args, options)
      each_subscription(args) do |subscription|
        days = subscription.dormant_days
        if days.nil?
          puts "#{subscription.id}: never modified"
        elsif days > DormantPeriod
          puts "#{subscription.id}: not modified for over #{days.to_i} days"
        end
      end
    end

  end

end