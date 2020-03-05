module NewsFetcher

  class Subscription

    attr_accessor :title
    attr_accessor :link
    attr_accessor :profile
    attr_accessor :dir
    attr_accessor :history

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

    def age
      if (t = latest_item_timestamp)
        Date.today - t.to_date
      else
        nil
      end
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
      raise Error, "Link not defined" unless @link
      begin
        response = NewsFetcher.get(@link, if_modified_since: last_modified)
      rescue Error => e
        raise Error, "Failed to get #{@link}: #{e}"
      end
      if response
        @profile.logger.debug { "#{id}: Loaded feed: #{@link}" }
        if response[:redirect]
          @profile.logger.warn { "#{id}: Feed has moved from #{@link} to #{response[:redirect]}" }
        end
        feed_file.write(response[:content])
        feed_file.utime(response[:last_modified], response[:last_modified])
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

    DetailsFields = [
      [ 'ID', proc { |s| s.id } ],
      [ 'Title', proc { |s| s.title } ],
      [ 'Link', proc { |s| s.link } ],
      [ 'Items', proc { |s| s.history.length } ],
      [ 'Status', proc { |s| s.status } ],
      [ 'Last modified', proc { |s| s.last_modified } ],
      [ 'Age', proc { |s| s.age ? "#{s.age.to_i} days" : 'never' } ],
    ]
    DetailsFieldsMaxWidth = DetailsFields.map { |i| i.first.length }.max

    def show_details
      DetailsFields.each do |label, prc|
        puts '%*s: %s' % [
          DetailsFieldsMaxWidth,
          label,
          prc.call(self),
        ]
      end
      puts
    end

    def show_summary
      puts "%8s | %10s | %5d | %-40.40s | %-40.40s" % [
        status,
        (a = age) ? "#{a.to_i} days" : 'never',
        history.length,
        title,
        id,
      ]
    end

  end

end