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
        $logger.warn { "#{@id}: URI #{resource.uri} moved to #{resource.redirected_uri}" }
      end
      @feed = Feed.new_from_resource(resource)
      @feed.save(feed_file)
      ignore_patterns = @config.ignore ? [@config.ignore].flatten.map { |r| Regexp.new(r) } : nil
      new_items = @feed.items.values.
        reject { |item| (ignore_patterns && ignore_patterns.find { |r| item.uri.to_s =~ r }) }.
        reject { |item| @history.include?(item.id) }.
        reject { |item| item.age > @config.dormant_time }
      new_items.each { |item| @history[item.id] = item.date }
      @history.save
      new_items.each do |item|
        mail_item(item)
      end
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

    def mail_item(item)
      template = Path.new(@config.message_template).read
      msg = ERB.new(template).result(binding)
      mail = Mail.new(msg)
      deliver_method, deliver_params =
        @config.deliver_method&.to_sym, @config.deliver_params
      $logger.info { "#{@id}: Sending item via #{deliver_method || 'default'}: #{item.title.inspect}" }
      case deliver_method.to_sym
      when :maildir
        location = deliver_params.location or raise Error, "location not found in deliver_params"
        dir = Path.new(location).expand_path
        folder = '.' + path('.')
        maildir = Maildir.new(dir / folder)
        maildir.serializer = Maildir::Serializer::Mail.new
        maildir.add(mail)
      else
        mail.delivery_method(deliver_method, deliver_params) if deliver_method
        mail.deliver!
      end
    end

    def render_html_content(content)
      Loofah.fragment(content).
        scrub!(:prune).
        scrub!(Scrubber::RemoveExtras).
        scrub!(Scrubber::RemoveVoxFooter).
        scrub!(Scrubber::RemoveStyling).
        scrub!(Scrubber::ReplaceBlockquote).
        to_html
    end

    def render_text_content(content)
      Simple::Builder.html_fragment do |html|
        content.split("\n").each_with_index do |line, i|
          html.br unless i == 0
          html.text(line)
        end
      end.to_html
    end

    #
    # methods for ERB binding
    #

    def mail_from
      mail_from = @config.mail_from or raise Error, "mail_from not specified in config"
      ERB.new(mail_from).result(binding)
    end

    def mail_to
      mail_to = @config.mail_from or raise Error, "mail_to not specified in config"
      ERB.new(mail_to).result(binding)
    end

    def mail_body
      template = Path.new(@config.html_template).read
      ERB.new(template).result(binding)
    end

    def styles
      Simple::Builder.html_fragment do |html|
        @styles.each do |style|
          html.style { html << style }
        end
      end.to_html
    end

    def item_content_html(item)
      if item.content
        if item.content.html?
          render_html_content(item.content)
        else
          render_text_content(item.content)
        end
      else
        ''
      end
    end

  end

end