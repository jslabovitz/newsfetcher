module NewsFetcher

  class Subscription

    attr_accessor :title
    attr_reader   :link
    attr_accessor :ignore
    attr_accessor :profile
    attr_reader   :dir
    attr_accessor :history

    def self.name_to_key(name)
      name.
        downcase.
        gsub(/[^a-z0-9]+/, ' ').  # non-alphanumeric
        strip.
        gsub(/\s+/, '-')
    end

    def self.uri_to_key(uri)
      uri = Addressable::URI.parse(uri)
      host = uri.host.to_s.sub(/^(www|ssl|en|feeds|rss|blogs?|news).*?\./i, '').sub(/\.(com|org|net|info|edu|co\.uk|wordpress\.com|blogspot\.com)$/i, '')
      host = '' if host == 'feedburner'
      path = uri.path.to_s.gsub(/\b(\.?feeds?|index|atom|rss|rss2|xml|php|blog|posts|default)\b/i, '')
      query = uri.query.to_s.gsub(/\b(format|feed|type|q)=(atom|rss\.xml|rss2?|xml)/i, '')
      name_to_key([host, path, query].reject(&:empty?).join('-'))
    end

    def initialize(params={})
      @title = @link = @profile = @dir = @history = nil
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

    def ignore=(ignore)
      @ignore = [ignore].flatten.map { |r| Regexp.new(r) }
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

    def result_file
      @dir / ResultFileName
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

    def should_ignore_item?(item)
      @ignore && @ignore.find { |r| item.url.to_s =~ r }
    end

    def update
      raise Error, "Link not defined" unless @link
      headers = {}
      if result_file.exist?
        result = Result.load(result_file)
        if (date = (result.headers[:date] rescue nil))
          headers = { if_modified_since: date }
        end
      end
      result = NewsFetcher.get(@link, headers: headers)
      case result.type
      when :moved
        @profile.logger.warn { "Feed has moved from #{@link}: #{result.reason}" }
      when :not_modified
        # skip
      when :successful
        result.save(result_file)
      else
        raise Error, "Failed request: #{result.reason} (type=#{result.type.type}, status=#{result.status.inspect})"
      end
    end

    def process
      read_feed
      @items.each do |item|
        if @history[item.id] || item.age > DefaultDormantTime
          @profile.logger.info { "#{id}: Skipping obsolete item: #{item.url}" }
          next
        end
        if should_ignore_item?(item)
          @profile.logger.info { "#{id}: Skipping ignored item: #{item.url}" }
        else
          @profile.send_item(item)
        end
        @history[item.id] = item.date
      end
    end

    def read_feed
      result = Result.load(result_file)
      case result.content
      when /^</
        read_xml_feed(result.content)
      when /^\{/
        read_json_feed(result.content)
      else
        raise Error, "Unknown content type for feed: #{(result.content[0..9] + '...').inspect}"
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
      result_file.unlink if result_file.exist?
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