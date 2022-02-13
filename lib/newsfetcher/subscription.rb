module NewsFetcher

  class Subscription

    attr_accessor :id
    attr_accessor :title
    attr_reader   :uri
    attr_accessor :ignore
    attr_accessor :disable
    attr_reader   :dir

    include SetParams

    def self.name_to_id(*names, path: nil)
      id = names.
        join(' ').
        downcase.
        gsub(/[^a-z0-9]+/, ' ').  # non-alphanumeric
        strip.
        gsub(/\s+/, '-')
      id = "#{path}/#{id}" if path
      id
    end

    def self.uri_to_id(uri, path: nil)
      uri = Addressable::URI.parse(uri)
      uri_host = uri.host.to_s.sub(/^(www|ssl|en|feeds|rss|blogs?|news).*?\./i, '').sub(/\.(com|org|net|info|edu|co\.uk|wordpress\.com|blogspot\.com)$/i, '')
      uri_host = '' if uri_host == 'feedburner'
      uri_path = uri.path.to_s.gsub(/\b(\.?feeds?|index|atom|rss|rss2|xml|php|blog|posts|default)\b/i, '')
      uri_query = uri.query.to_s.gsub(/\b(format|feed|type|q)=(atom|rss\.xml|rss2?|xml)/i, '')
      name_to_id(uri_host, uri_path, uri_query, path: path)
    end

    def initialize(params={})
      set(params)
      raise Error, "dir not set" unless @dir
      @bundle = Bundle.new(@dir)
      raise Error, "uri not set" unless @uri
      @feed = feed_file.exist? ? Feed.load(feed_file) : Feed.new(uri: @uri, title: @title)
      if history_file.exist?
        @history = History.load(file: history_file)
        @history.prune(before: DateTime.now - DefaultDormantTime)
        @history.save
      else
        @history = History.new(file: history_file)
      end
    end

    def path(delim='/')
      @id.split('/')[0..-2].join(delim)
    end

    def dir=(dir)
      @dir = Path.new(dir)
    end

    def uri=(uri)
      @uri = Addressable::URI.parse(uri)
    end

    def ignore=(ignore)
      @ignore = [ignore].flatten.map { |r| Regexp.new(r) }
    end

    def feed_file
      @dir / FeedFileName
    end

    def history_file
      @dir / HistoryFileName
    end

    def exist?
      @dir.exist?
    end

    def save
      @bundle.info = {
        title: @title,
        uri: @uri&.to_s,
        ignore: @ignore,
        disable: @disable,
      }.compact
      @bundle.save
    end

    def age
      if (date = @feed.last_item_date)
        Time.now - date
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
      @feed = Feed.get(@uri)
      @feed.save(feed_file)
      @title ||= @feed.title
      new_items = @feed.items.values.
        reject { |item| (@ignore && @ignore.find { |r| item.uri.to_s =~ r }) }.
        reject { |item| @history.include?(item.id) }.
        reject { |item| item.age > DefaultDormantTime }
      new_items.each { |item| @history[item.id] = item.date }
      @history.save
      new_items
    end

    def reset
      feed_file.unlink if feed_file.exist?
      @history.reset
    end

    def remove
      @dir.rmtree
    end

    def fix
      @history.reset
      @feed.items.each do |id, item|
        @history[item.id] = item.date
      end
      @history.save
    end

    def edit
      system(
        ENV['EDITOR'] || 'vi',
        @bundle.info_file.to_s)
    end

    FieldLabels = {
      id: 'ID',
      title: 'Title',
      uri: 'URI',
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
      puts "%8s | %10s | %-40.40s | %-40.40s" %
        %i{status age title id}.map { |key| show_field(key) }
    end

    def show_field(key)
      case key
      when :age
        if (a = age)
          '%d days' % (a / 60 / 60 / 24)
        else
          'never'
        end
      else
        send(key)
      end
    end

  end

end