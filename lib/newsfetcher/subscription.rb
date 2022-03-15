module NewsFetcher

  class Subscription

    attr_accessor :id
    attr_accessor :dir
    attr_accessor :config
    attr_accessor :styles
    attr_accessor :items
    attr_accessor :title

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

    def self.discover_feeds(uri, path: nil)
      uri = Addressable::URI.parse(uri)
      raise Error, "Bad URI: #{uri}" unless uri.absolute?
      begin
        resource = Resource.get(uri)
      rescue Error => e
        raise Error, "Failed to get #{uri}: #{e}"
      end
      html = Nokogiri::HTML::Document.parse(resource.content)
      html.xpath('//link[@rel="alternate"]').select { |link| FeedTypes.include?(link['type']) }.map do |link|
        feed_uri = uri.join(link['href'])
        Subscription.new(
          id: name_to_id(feed_uri, path: path),
          config: Config.new(uri: feed_uri))
      end
    end

    def initialize(params={})
      set(params)
      raise Error, "uri not set" unless @config.uri
      if @dir && history_file.exist?
        @history = History.load(history_file)
        @history.prune(before: Time.now - @config.dormant_time)
        @history.save(history_file)
      else
        @history = History.new
      end
    end

    def inspect
      to_s
    end

    def path(delim='/')
      @id.split('/')[0..-2].join(delim)
    end

    def config_file
      raise Error, "dir not set" unless @dir
      @dir / ConfigFileName
    end

    def history_file
      raise Error, "dir not set" unless @dir
      @dir / HistoryFileName
    end

    def exist?
      raise Error, "dir not set" unless @dir
      @dir.exist?
    end

    def save
      raise Error, "dir not set" unless @dir
      @dir.mkpath unless @dir.exist?
      @config.save(config_file)
    end

    def age
      if (time = @history.last_time)
        Time.now - time
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

    def update
      get
      ignore_patterns = @config.ignore ? [@config.ignore].flatten.map { |r| Regexp.new(r) } : nil
      @items.reject { |item|
        (ignore_patterns && ignore_patterns.find { |r| item.uri.to_s =~ r }) \
        || @history.include?(item.id) \
        || item.age > @config.dormant_time
       }.each do |item|
        send_mail(make_mail(item))
        @history[item.id] = item.published
        @history.save(history_file)
      end
    end

    def get
      resource = Resource.get(@config.uri)
      if resource.moved && !@config.ignore_moved
        $logger.warn { "#{@id}: URI #{resource.uri} moved to #{resource.redirected_uri}" }
      end
      Feedjira.configure { |c| c.strip_whitespace = true }
      begin
        feedjira = Feedjira.parse(resource.content.force_encoding(Encoding::UTF_8))
      rescue StandardError, Feedjira::NoParserAvailable, Date::Error => e
        raise Error, "Can't parse XML feed from #{resource.uri}: #{e}"
      end
      @title = feedjira.title
      @items = feedjira.entries.map { |e| item_for_entry(e) }
    end

    def item_for_entry(entry)
      uri = nil
      if entry.url
        begin
          uri = Addressable::URI.parse(entry.url.strip)
        rescue Addressable::URI::InvalidURIError => e
          raise Error, "Can't parse URL for entry: #{entry.url.inspect}"
        end
      end
      id = entry.entry_id
      unless id
        raise Error, "No ID or URL for entry" unless uri
        if uri.scheme == 'http' || uri.scheme == 'https'
          uri.host = uri.host.sub(/^www\./, '')
        end
        id = uri.to_s
      end
      Item.new(
        id: id,
        published: entry.published || Time.now,
        title: entry.title,
        uri: uri,
        author: entry.respond_to?(:author) ? entry.author : nil,
        content: render_content(entry.content || entry.summary || ''),
      )
    end

    def reset
      @history.reset(history_file)
    end

    def remove
      raise Error, "dir not set" unless @dir
      @dir.rmtree
    end

    def fix
    end

    def edit
      system(
        ENV['EDITOR'] || 'vi',
        config_file.to_s)
    end

    Fields = {
      id: { label: 'ID', format: '%-30.30s' },
      uri: { label: 'URI', format: '%-30.30s' },
      status: { label: 'Status', format: '%-10s' },
      age: { label: 'Age', format: '%-10s' },
    }
    FieldsMaxWidth = Fields.map { |k, v| v[:label].length }.max

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
            field[:format] % value
          end.join(' | ')
        )
      when :list
        fields.each do |key, value|
          field = Fields[key] or raise
          io.puts '%*s: %s' % [
            FieldsMaxWidth,
            field[:label],
            value,
          ]
        end
        io.puts
      else
        raise
      end
    end

    def make_mail(item)
      mail_from    = @config.mail_from or raise Error, "mail_from not specified in config"
      mail_to      = @config.mail_to or raise Error, "mail_to not specified in config"
      mail_subject = @config.mail_subject or raise Error, "mail_subject not specified in config"
      fields = {
        subscription_id: @id,
        item_title: item.title,
      }
      mail = Mail.new
      mail.date =         item.published
      mail.from =         ERB.new(mail_from).result_with_hash(fields)
      mail.to =           ERB.new(mail_to).result_with_hash(fields)
      mail.subject =      ERB.new(mail_subject).result_with_hash(fields)
      mail.content_type = 'text/html'
      mail.charset      = 'utf-8'
      {
        'ID' => @id,
        'Date' => @date,
        'Title' => @title,
        'Author' => @author,
        'URL' => @url,
      }.compact.each { |k, v| mail["X-Newsfetcher-#{k}"] = v.to_s }
      mail.body         = render_item(item).to_html
      mail
    end

    def send_mail(mail)
      deliver_method, deliver_params =
        @config.deliver_method&.to_sym, @config.deliver_params
      $logger.info { "#{@id}: Sending item via #{deliver_method || 'default'}: #{mail.subject.inspect}" }
      case deliver_method.to_sym
      when :maildir
        location = deliver_params[:location] or raise Error, "location not found in deliver_params"
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

    def render_item(item)
      make_styles unless @styles
      Simple::Builder.html4_document do |html|
        html.html do
          html.head do
            html.meta(name: 'x-apple-disable-message-reformatting')
            html.meta(name: 'viewport', content: 'width=device-width, initial-scale=1')
            @styles.each do |style|
              html.style { html << style }
            end
          end
          html.body do
            html.div(class: 'header') do
              html << ('%s [%s]' % [@config.title || @title, @id]).to_html
            end
            html.h1 do
              html << item.title.to_html
            end
            html.h2 do
              html << item.byline.to_html
            end
            if item.uri
              html.h3 do
                html.a(item.uri.prettify, href: item.uri)
              end
            end
            if item.content
              html.div(class: 'content') { html << item.content }
            end
          end
        end
      end
    end

    def render_content(content)
      if content
        if content.html?
          render_html_content(content)
        else
          render_text_content(content)
        end
      else
        ''
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

    def make_styles
      raise Error, "dir not set" unless @dir
      @styles = [@config.main_stylesheet, @config.aux_stylesheets].compact.map do |file|
        file = Path.new(file)
        file = @dir / file if file.relative?
        SassC::Engine.new(file.read, syntax: :scss, style: :compressed).render
      end
    end

  end

end