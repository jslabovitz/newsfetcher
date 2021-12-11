module NewsFetcher

  class Subscription

    attr_accessor :title
    attr_reader   :link
    attr_accessor :ignore
    attr_accessor :profile
    attr_reader   :dir

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
      @title = @link = @profile = @dir = nil
      params.each { |k, v| send("#{k}=", v) if v }
      raise Error, "dir not set" unless @dir
      @bundle = Bundle.new(@dir)
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
      if (date = @items&.map(&:date).sort.last)
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

    def should_ignore_item?(item)
      item.age > DefaultDormantTime || (@ignore && @ignore.find { |r| item.url.to_s =~ r })
    end

    def update
      raise Error, "Link not defined" unless @link
      headers = {}
      old_result = nil
      if result_file.exist?
        old_result = Result.load(result_file, subscription: self)
        if (date = (old_result.headers[:date] rescue nil))
          headers = { if_modified_since: date }
        end
      end
      new_result = Result.get(@link, headers: headers, subscription: self)
      case new_result.type
      when :moved
        @profile.logger.warn { "Feed has moved from #{@link}: #{new_result.reason}" }
      when :not_modified
        # skip
      when :successful
        @title = new_result.title || 'untitled'
        old_items = old_result.items_hash
        new_items = new_result.items_hash
        new_items.delete_if { |id, item| old_items[id] || should_ignore_item?(item) }
        new_items.values.each do |item|
          @profile.logger.debug { "#{id}: Sending item: #{item.to_info}" }
          @profile.send_item(item)
        end
      else
        raise Error, "Failed request [#{new_result.type}]: #{new_result.reason} (#{new_result.status})"
      end
      new_result.save(result_file)
    end

    def reset
      result_file.unlink if result_file.exist?
    end

    def remove
      @dir.rmtree
    end

    def fix
    end

    def edit
      system(
        ENV['EDITOR'] || 'vi',
        @bundle.info_file.to_s)
    end

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
      case key
      when :items
        @items.length
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