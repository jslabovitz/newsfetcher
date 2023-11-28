module NewsFetcher

  class Subscription

    attr_accessor :id
    attr_accessor :dir
    attr_accessor :config
    attr_accessor :styles
    attr_accessor :items
    attr_accessor :title

    include SetParams
    include Simple::Printer::Printable

    def self.make_id(uri)
      [
        uri.host.to_s \
          .sub(/^(www|ssl|en|feeds|rss|blogs?|news).*?\./i, '') \
          .sub(/\.(com|org|net|info|edu|co\.uk|wordpress\.com|blogspot\.com|feedburner\.com)$/i, ''),
        uri.path.to_s \
          .gsub(/\b(\.?feeds?|index|atom|rss|rss2|xml|rdf|php|blog|posts|default)\b/i, ''),
        uri.query.to_s \
          .gsub(/\b(format|feed|type|q)=(atom|rss\.xml|rss2?|xml)/i, ''),
      ] \
        .join(' ')
        .downcase
        .gsub(/[^a-z0-9]+/, ' ')  # non-alphanumeric
        .strip
        .gsub(/\s+/, '-')
    end

    def initialize(params={})
      @title = nil
      @items = []
      super
      @ignore_uris = [@config.ignore_uris].flatten.compact.map { |r| Regexp.new(r) }
      @formatter = Formatter.new(styles: @styles, subscription: self)
      load_history
    end

    def inspect
      to_s
    end

    def printable
      [
        [:id, 'ID'],
        [:uri, 'URI', config.uri],
        :dir,
        :title,
        :status,
        [:age, 'Age', (a = age) ? '%d days' % (a / 60 / 60 / 24) : 'never'],
        [:disable, 'Disable', config.disable],
        :items,
      ]
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

    def effective_title
      @config.title || @title
    end

    def age
      latest_key, latest_time = @history.latest_entry
      if latest_time
        Time.now - latest_time
      else
        nil
      end
    end

    def status
      if (a = age)
        if a > @config.max_age
          :dormant
        else
          :active
        end
      else
        :new
      end
    end

    def load_history
      if @dir && history_file.exist?
        @history = History.load(history_file)
        @history.prune(before: Time.now - @config.max_age) do |id, time|
          $logger.info { "pruning #{id.inspect} (#{time})"}
        end
        @history.save
      elsif @dir
        @history = History.new(file: history_file)
      else
        @history = History.new
      end
    end

    def update_history
      @items.each do |item|
        #FIXME: make entry with timestamp
        @history[item.id] = item.date
      end
      @history.save
    end

    def update
      $logger.debug { "#{@id}: updating" }
      begin
        get
        reject_items
        update_history
        deliver
      rescue Error => e
        $logger.error { "#{@id}: #{e}" }
      end
    end

    def get
      @title = nil
      @items = []
      uri = @config.uri or raise Error, "No URI defined for #{@id}"
      uri = Addressable::URI.parse(uri)
      resource = Resource.get(uri)
      if resource.moved && !@config.ignore_moved
        $logger.warn { "#{@id}: URI #{resource.uri} moved to #{resource.redirected_uri}" }
      end
      Feedjira.configure { |c| c.strip_whitespace = true }
      begin
        feedjira = Feedjira.parse(resource.content)
      rescue StandardError, Feedjira::NoParserAvailable, Date::Error => e
        raise Error, "Can't parse XML feed from #{resource.uri}: #{e}"
      end
      @title ||= feedjira.title
      @items += feedjira.entries.map { |e| Item.new(e) }
    end

    def reject_items
      @items.reject! do |item|
        if (reason = reject_item?(item))
          $logger.debug { "#{@id}: removing item: #{reason} #{item.id}" }
          true
        end
      end
    end

    def reject_item?(item)
      if item.age > @config.max_age
        'outdated item'
      elsif @history.include?(item.id)
        'seen item'
      elsif @ignore_uris.find { |r| item.uri.to_s =~ r }
        'ignored item'
      end
    end

    def deliver
      raise "No formatter defined" unless @formatter
      $logger.debug { "#{@id}: no items to deliver" } if @items.empty?
      @items.sort_by(&:date).each do |item|
        mail = @formatter.make_mail(item: item)
        send_mail(mail)
      end
    end

    def enable
      @config.disable = false
      save
    end

    def disable
      @config.disable = true
      save
    end

    def reset
      @history.reset
    end

    def remove
      raise Error, "dir not set" unless @dir
      @dir.rmtree
    end

    def fix
      @history.save
    end

    def edit
      editor = ENV['EDITOR'] or raise Error, "No editor defined in $EDITOR"
      system(editor, config_file.to_s)
    end

    def send_mail(mail)
      deliver_method, deliver_params =
        @config.deliver_method&.to_sym, @config.deliver_params
      $logger.info { "#{@id}: Sending item to #{mail.to.join(', ')} via #{deliver_method || 'default'}: #{mail.subject.inspect}" }
      case deliver_method.to_sym
      when :maildir
        location = deliver_params[:location] or raise Error, "location not found in deliver_params"
        folder = deliver_params[:folder]
        dir = maildir_directory(location: location, folder: folder)
        maildir = Maildir.new(dir)
        maildir.serializer = Maildir::Serializer::Mail.new
        maildir.add(mail)
      else
        mail.delivery_method(deliver_method, deliver_params) if deliver_method
        mail.perform_deliveries = true
        mail.deliver!
      end
    end

    def maildir_directory(location:, folder:)
      location = Path.new(location).expand_path
      components = @id.split('/')
      components.pop if @config.consolidate && components.length > 1
      components.unshift(folder) if folder
      components.unshift('')
      location / components.join('.')
    end

  end

end