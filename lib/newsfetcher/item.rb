module NewsFetcher

  class Item

    attr_reader   :id
    attr_reader   :date
    attr_reader   :title
    attr_reader   :uri
    attr_reader   :author
    attr_reader   :content
    attr_accessor :is_new

    include SetParams

    def id=(id)
      @id = (s = id.to_s.strip).empty? ? nil : s
      # drop 'www.' prefix from ID if necessary
      if @id
        begin
          uri = Addressable::URI.parse(@id)
          uri.host = uri.host.sub(/^www\./, '')
          @id = uri.to_s
        rescue
          nil
        end
      end
    end

    def date=(date)
      @date = case date
      when String
        Time.parse(date)
      when Time, nil
        date
      else
        raise Error, "Unknown date value: #{date.inspect}"
      end
    end

    def title=(title)
      @title = (s = title.to_s.strip).empty? ? nil : s
    end

    def uri=(uri)
      @uri = case uri
      when String
        Addressable::URI.parse(uri.strip)
      when Addressable::URI, URI, nil
        uri
      else
        raise Error, "Unknown URI value: #{uri.inspect}"
      end
    end

    def author=(author)
      @author = (s = author.to_s.strip).empty? ? nil : s
    end

    def content=(content)
      @content = (s = content.to_s.strip).empty? ? nil : s
    end

    def title_html
      if @title.html?
        @title.to_html
      else
        @title
      end
    end

    def byline
      [@author, @date.strftime('%e %B %Y')]
        .map(&:to_s)
        .map(&:strip)
        .reject(&:empty?)
        .join(' • ')
    end

    def eql?(other)
      @id.eql?(other.id)
    end

    def ==(other)
      @id == other.id
    end

    def to_h
      {
        id: @id,
        date: @date,
        title: @title,
        uri: @uri,
        author: @author,
        content: @content,
      }
    end

    def as_json(*options)
      to_h.compact
    end

    def to_json(*options)
      as_json(*options).to_json(*options)
    end

    def to_info
      %i[id date title author uri].map do |key|
        value = send(key)
        value = '-' if value.nil?
        '%s="%s"' % [key, value]
      end.join(', ')
    end

    def render_content
      if @content
        if @content.html?
          render_html_content
        else
          render_text_content
        end
      end
    end

    def age
      Time.now - @date
    end

    def digest
      Digest::SHA256.hexdigest([@date, @title, @author, @content].join('|'))
    end

    DefaultKeys = %i{id date title uri author content}

    def show(keys=nil)
      keys ||= DefaultKeys
      keys.each do |key|
        value = send(key)
        if value =~ /\n/
          puts '%20s:' % key
          value.split(/\n/).each { |v| puts '  | %s' % v }
        else
          puts '%20s: %s' % [key, value]
        end
      end
    end

  end

end