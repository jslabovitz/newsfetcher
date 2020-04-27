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

    def age
      if (timestamp = @history.latest&.last)
        Time.now - timestamp
      else
        nil
      end
    end

    def status
      if (a = age)
        if a > DefaultDormantTime
          :dormant
        else
          :active
        end
      else
        :new
      end
    end

    def update
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

    def process
      read_feed
      @items.each do |item|
        next if @history[item.id] || item.age > DefaultDormantTime
        @profile.send_item(item)
        @history[item.id] = item.date
      end
    end

    def read_feed
      raise Error, "No feed file" unless feed_file.exist?
      feed_data = feed_file.read
      case feed_data
      when /^</
        read_xml_feed(feed_data)
      when /^\{/
        read_json_feed(feed_data)
      else
        raise Error, "Unknown feed type"
      end
    end

    def read_xml_feed(data)
      begin
        Feedjira.configure { |c| c.strip_whitespace = true }
        feed = Feedjira.parse(data)
      rescue => e
        raise Error, "Can't parse XML feed: #{e}"
      end
      @title ||= feed.title || 'untitled'
      @items = feed.entries.map do |entry|
        Item.new(
          subscription: self,
          id: entry.entry_id || entry.url,
          date: entry.published || Time.now,
          title: entry.title,
          url: entry.url,
          author: entry.respond_to?(:author) ? entry.author : nil,
          content: entry.content || entry.summary || '')
      end
    end

    def read_json_feed(data)
      begin
        feed = JSON.parse(data)
      rescue => e
        raise Error, "Can't parse JSON feed: #{e}"
      end
      @title ||= feed['title'] || 'untitled'
      @items = feed['items'].map do |item|
        Item.new(
          subscription: self,
          id: item['id'] || item['url'],
          date: item['date_published'] || Time.now,
          title: item['title'],
          url: item['url'],
          author: item['author'] && item['author']['name'],
          content: item['content_html'] || item['summary'])
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

    FieldFormatters = {
      items: proc { |s|
        s.history.length
      },
      age: proc { |s|
        if (a = s.age)
          '%d days' % (a / 60 / 60 / 24)
        else
          'never'
        end
      },
    }

    FieldLabels = {
      id: 'ID',
      title: 'Title',
      link: 'Link',
      items: 'Items',
      status: 'Status',
      last_modified: 'Last modified',
      age: 'Age',
    }
    FieldLabelsMaxWidth = FieldLabels.map { |k, v| v.length }.max

    def show_details
      FieldLabels.each do |key, label|
        puts '%*s: %s' % [
          FieldLabelsMaxWidth,
          label,
          show_field(key),
        ]
      end
      puts
    end

    def show_summary
      puts "%8s | %10s | %5d | %-40.40s | %-40.40s" %
        %i{status age items title id}.map { |key| show_field(key) }
    end

    def show_field(key)
      if (p = FieldFormatters[key])
        p.call(self)
      else
        send(key)
      end
    end

  end

end