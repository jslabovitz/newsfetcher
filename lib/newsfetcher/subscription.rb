module NewsFetcher

  class Subscription

    attr_accessor :title
    attr_accessor :link
    attr_accessor :profile
    attr_accessor :dir
    attr_accessor :history

    def self.find(dir:, profile:, ids: nil)
      if ids && !ids.empty?
        bundles = ids.map { |a| (a =~ %r{^[/~.]}) ? Path.new(a) : (dir / a) }.map { |d| Bundle.new(d) }
      else
        bundles = Bundle.bundles(dir)
      end
      bundles.map do |bundle|
        new(bundle.info.merge(profile: profile, dir: bundle.dir))
      end
    end

    def self.load(params={})
      new(params)
    end

    def self.uri_to_key(uri)
      uri = Addressable::URI.parse(uri)
      host = uri.host.to_s.sub(/^(www|ssl|en|feeds|rss|blogs?|news).*?\./i, '').sub(/\.(com|org|net|info|edu|co\.uk|wordpress\.com|blogspot\.com)$/i, '')
      host = '' if host == 'feedburner'
      path = uri.path.to_s.gsub(/\b(\.?feeds?|index|atom|rss|rss2|xml|php|blog|posts|default)\b/i, '')
      query = uri.query.to_s.gsub(/\b(format|feed|type|q)=(atom|rss\.xml|rss2?|xml)/i, '')
      [host, path, query].
        reject(&:empty?).
        join('-').
        downcase.
        gsub(/[^a-z0-9]+/, ' ').  # non-alphanumeric
        strip.
        gsub(/\s+/, '-')
    end

    def initialize(params={})
      params.each { |k, v| send("#{k}=", v) if v }
      raise Error, "dir not set" unless @dir
      @bundle = Bundle.new(@dir)
      @history = History.new(dir / HistoryFileName)
    end

    def dir=(dir)
      @dir = Path.new(dir)
    end

    def link=(link)
      @link = link.kind_of?(Addressable::URI) ? link : Addressable::URI.parse(link)
    end

    def relative_dir
      @dir.relative_to(@profile.subscriptions_dir)
    end

    def id
      relative_dir.to_s
    end

    def base_id
      relative_dir.basename.to_s
    end

    def feed_file
      @dir / FeedFileName
    end

    def last_modified
      feed_file.exist? ? feed_file.mtime : nil
    end

    def exist?
      @dir.exist?
    end

    def save
      @bundle.info.title = @title
      @bundle.info.link = @link
      @bundle.save
    end

    def latest_item_timestamp
      @history.latest&.last
    end

    def status
      last = latest_item_timestamp
      if last
        if (Time.now - last) > DefaultDormantTime
          :dormant
        else
          :active
        end
      else
        :new
      end
    end

    def update_feed
      begin
        response = @profile.get(@link, last_modified ? { if_modified_since: last_modified.rfc2822 } : nil)
      rescue StandardError => e
        raise Error, "Couldn't get #{@link}: #{e}"
      end
      if response
        @profile.logger.debug { "#{id}: loaded feed: #{@link}" }
        last_modified = Time.parse(response.headers[:last_modified] || response.headers[:date])
        feed_file.write(response.body)
        feed_file.utime(last_modified, last_modified)
      end
    end

    def process(&block)
      feed = parse_feed
      feed_items(feed).each do |item|
        next if @history[item.id] || item.age > DefaultDormantTime
        yield(item)
        @history[item.id] = item.date
      end
    end

    def parse_feed
      raise Error, "No feed file" unless feed_file.exist?
      feed = feed_file.read
      begin
        Feedjira.configure { |c| c.strip_whitespace = true }
        Feedjira.parse(feed)
      rescue => e
        raise Error, "Can't parse feed from #{feed_file}: #{e}"
      end
    end

    def feed_items(feed)
      feed.entries.collect do |entry|
        Item.new(
          feed: feed,
          entry: entry,
          subscription: self,
          profile: @profile)
      end
    end

    def reset
      feed_file.unlink if file.exist?
      @history.reset
    end

    def remove
      @dir.rmtree
    end

    def fix
    end

    def show(keys)
      feed = parse_feed
      puts; puts '%s:' % (@title || feed.title)
      feed_items(feed).each do |item|
        item.show(keys)
        puts
      end
    end

    def show_message
      feed = parse_feed
      feed_items(feed).each do |item|
        email = item.make_email
        puts email.header
        puts
        puts email.body
      end
    end

  end

end