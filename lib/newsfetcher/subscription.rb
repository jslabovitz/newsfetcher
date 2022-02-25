module NewsFetcher

  class Subscription

    attr_accessor :id
    attr_accessor :dir
    attr_accessor :config
    attr_accessor :styles

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
      setup_styles
      raise Error, "uri not set" unless @config.uri
      @feed = feed_file.exist? ? Feed.load(feed_file) : Feed.new(uri: @config.uri, title: @config.title)
      if history_file.exist?
        @history = History.load(file: history_file)
        @history.prune(before: DateTime.now - @config.dormant_time)
        @history.save
      else
        @history = History.new(file: history_file)
      end
    end

    def inspect
      to_s
    end

    def path(delim='/')
      @id.split('/')[0..-2].join(delim)
    end

    def ignore=(ignore)
      @ignore = [ignore].flatten.map { |r| Regexp.new(r) }
    end

    def config_file
      @dir / ConfigFileName
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
      @dir.mkpath unless @dir.exist?
      @config.save(config_file)
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
        if a > @config.dormant_time
          :dormant
        else
          :active
        end
      else
        :new
      end
    end

    def setup_styles
      @styles = stylesheet_files.map do |file|
        SassC::Engine.new(file.read, syntax: :scss, style: :compressed).render
      end
    end

    def stylesheet_files
      [@config.main_stylesheet, @config.aux_stylesheets].compact.map do |file|
        file = Path.new(file)
        file = @dir / file if file.relative?
        file
      end
    end

    def final_title
      @config.title ||= @feed.title
    end

    def update
      resource = Resource.get(@config.uri)
      if resource.moved && !@config.ignore_moved
        $logger.warn { "#{id}: URI #{resource.uri} moved to #{resource.redirected_uri}" }
      end
      @feed = Feed.new_from_resource(resource)
      @feed.save(feed_file)
      new_items = @feed.items.values.
        reject { |item| (@config.ignore && @config.ignore.find { |r| item.uri.to_s =~ r }) }.
        reject { |item| @history.include?(item.id) }.
        reject { |item| item.age > @config.dormant_time }
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
        config_file.to_s)
    end

    Fields = HashStruct.new(
      id: { label: 'ID', format: '%-30.30s' },
      uri: { label: 'URI', format: '%-30.30s' },
      status: { label: 'Status', format: '%-10s' },
      age: { label: 'Age', format: '%-10s' },
    )
    FieldsMaxWidth = Fields.map { |k, v| v.label.length }.max

    def print(io=STDOUT, format: nil)
      fields = {
        id: @id,
        uri: @config.uri,
        status: status,
        age: ((a = age) ? '%d days' % (a / 60 / 60 / 24) : 'never'),
      }
      case format
      when nil, :table
        io.puts(
          fields.map do |key, value|
            field = Fields[key] or raise
            field.format % value
          end.join(' | ')
        )
      when :list
        fields.each do |key, value|
          field = Fields[key] or raise
          io.puts '%*s: %s' % [
            FieldsMaxWidth,
            field.label,
            value,
          ]
        end
        io.puts
      else
        raise
      end
    end

  end

end