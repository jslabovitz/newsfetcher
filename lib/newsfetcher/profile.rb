module NewsFetcher

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
      Maildir.new((@maildir / @folder / feed.path.dirname).to_s)
    end

    def style
      @style ||= NewsFetcher::StylesheetFile.read
    end

    def message_template
      @message_template ||= MessageTemplateFile.read
    end

    def load_feed(dir)
      Feed.load(profile: self, path: dir.relative_to(feeds_dir))
    end

    def feeds(args=[])
      if args.empty?
        dirs = feeds_dir.glob("**/#{FeedInfoFileName}").map(&:dirname)
      else
        dirs = args.map { |a| (a =~ %r{^[/~]}) ? Path.new(a) : (feeds_dir / a) }
      end
      dirs.map do |dir|
        Feed.load(profile: self, path: dir)
      end
    end

    # def update_feeds(feed_dirs, **options)
    #   # threads = []
    #   feed_dirs.each do |feed_dir|
    #     # threads << Thread.new do
    #       begin
    #         feed = load_feed(feed_dir)
    #         feed.update(options)
    #       rescue Error => e
    #         warn "#{feed_dir}: #{e}"
    #         # Thread.exit
    #       end
    #     # end
    #   end
    #   # threads.map(&:join)
    # end

    def add_feed(uri:, path: nil)
      uri = URI.parse(uri)
      response = NewsFetcher.get(uri)
      raise Error, "Failed to get URI #{uri}: #{response.status}" unless response.success?
      begin
        Feedjira::Feed.parse(response.body)
      rescue Feedjira::NoParserAvailable => e
        new_uri = discover_feed(response.body)
        uri = new_uri.scheme ? new_uri : (uri + new_uri)
      end
      key = NewsFetcher.uri_to_key(uri)
      path = Path.new(path ? "#{path}/#{key}" : key)
      #FIXME: save feed
      feed = Feed.new(path: path, feed_link: uri, profile: self)
      raise Error, "Feed already exists (as #{feed.path}): #{uri}" if feed.exist?
      feed.save
      ;;warn "saved new feed to #{feed.info_file}"
    end

    def discover_feed(html_str)
      feeds = find_alternate_links(html_str)
      raise Error, "No alternate links" if feeds.empty?
      puts "Alternate links:"
      feeds.each_with_index do |link, i|
        puts "%2d. %s (%s): %s" % [i + 1, link[:href], link[:type], link[:title]]
      end
      loop do
        print "Choice? "
        i = gets.chomp.to_i
        return feeds[i - 1][:href] if i >= 1 && i <= feeds.length
      end
    end

    def find_alternate_links(html_str)
      html = Nokogiri::HTML::Document.parse(html_str)
      html.xpath('//link[@rel="alternate"]').map do |link_elem|
        {
          href: URI.parse(link_elem['href']),
          type: link_elem['type'],
          title: link_elem['title'],
        }
      end
    end

  end

end