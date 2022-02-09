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
    end

    def dir=(dir)
      @dir = Path.new(dir)
    end

    def uri=(uri)
      @uri = Addressable::URI.parse(uri)
    end

    def link=(link)
      #FIXME: remove after fixing subscription YAML files
      self.uri = link
    end

    def ignore=(ignore)
      @ignore = [ignore].flatten.map { |r| Regexp.new(r) }
    end

    def feed_file
      @dir / FeedFileName
    end

    def exist?
      @dir.exist?
    end

    def save
      @bundle.info.title = @title
      @bundle.info.uri = @uri
      @bundle.save
    end

    def new_items
      @feed.new_items
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

    def update(&block)
      new_feed = Feed.get(@uri)
      @title ||= new_feed.title
      @feed.merge!(new_feed,
        remove_dormant: DefaultDormantTime,
        ignore: @ignore)
      @feed.new_items.each do |item|
        yield(item)
      end
      @feed.save(feed_file)
    end

    def reset
      feed_file.unlink if feed_file.exist?
    end

    def remove
      @dir.rmtree
    end

    def fix
      %w[result.json history].map { |f| @dir / f }.each do |file|
        if file.exist?
          puts "Pruning: #{file}"
          file.unlink
        end
      end
      @bundle.info.delete(:link)
      save
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