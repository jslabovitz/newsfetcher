module NewsFetcher

  class Item

    attr_accessor :id
    attr_accessor :published
    attr_accessor :title
    attr_accessor :uri
    attr_accessor :author
    attr_accessor :content

    include SetParams

    def byline
      [@author&.sub(/^by\s+/i, ''), @published.strftime('%e %B %Y')]
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

    def age
      Time.now - @published
    end

    DefaultKeys = %i{id published title uri author content}

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