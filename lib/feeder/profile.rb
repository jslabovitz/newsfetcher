module Feeder

  class Profile

    attr_accessor :root_dir
    attr_accessor :maildir
    attr_accessor :folder
    attr_accessor :email

    def self.load(dir)
      info_file = dir / 'info.yaml'
      new(YAML.load(info_file.read).merge(root_dir: dir))
    end

    def initialize(params={})
      params.each { |k, v| send("#{k}=", v) }
    end

    def root_dir=(dir)
      @root_dir = Path.new(dir)
    end

    def maildir=(dir)
      @maildir = Path.new(dir)
    end

    def email=(address)
      @email = Mail::Address.new(address)
    end

    def to_yaml
      {
        email: @email.to_s,
        maildir: @maildir.to_s,
        folder: @folder,
      }.to_yaml(line_width: -1)
    end

    def feeds_dir
      @root_dir / 'feeds'
    end

    def maildir_for_feed(feed)
      Maildir.new(Path.new(@maildir, @folder, feed.id).to_s)
    end

    def style
      @style ||= Feeder::StylesheetFile.read
    end

    def select_feeds(args)
      if args.empty?
        dirs = feeds_dir.glob("**/#{FeedInfoFileName}").map(&:dirname)
      else
        dirs = args.map { |a| (a =~ %r{^[/~]}) ? Path.new(a) : (feeds_dir / a) }
      end
      dirs.map { |d| Feed.load(dir: d, profile: self) }
    end

    def update_feeds(feeds, **options)
      threads = []
      feeds.each do |feed|
        threads << Thread.new do
          begin
            feed.update(options)
          rescue Error => e
            warn "#{feed.id}: #{e}"
            Thread.exit
          end
        end
      end
      threads.map(&:join)
    end

    def add_feed(uri:, path: nil)
      uri = URI.parse(uri)
      response = Feeder.get(uri)
      raise Error, "Failed to get URI #{uri}: #{response.status}" unless response.success?
      begin
        Feedjira::Feed.parse(response.body)
      rescue Feedjira::NoParserAvailable => e
        feeds = find_feeds(response.body)
        raise Error, "No alternate links in URI: #{uri}" if feeds.empty?
        puts "Alternate links:"
        feeds.each do |uri, type, title|
          puts "\t%s (%s): %s" % [uri, type, title]
        end
        return
      end
      #FIXME: save feed
      feed = Feed.new(
        id: [path, Feeder.uri_to_key(uri)].flatten.compact.join('/'),
        feed_link: uri,
        profile: self)
      feed.save
      ;;warn "saved new feed to #{feed.info_file}"
    end

    def find_feeds(html_str)
      html = Nokogiri::HTML::Document.parse(html_str)
      html.xpath('//link[@rel="alternate"]').map do |link_elem|
        [
          # feed_link + URI.parse(link_elem['href']),
          link_elem['href'],
          link_elem['type'],
          link_elem['title'],
        ]
      end
    end

  end

end