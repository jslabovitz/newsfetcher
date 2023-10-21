module NewsFetcher

  class Item

    attr_accessor :id
    attr_accessor :date
    attr_accessor :title
    attr_accessor :uri
    attr_accessor :author
    attr_accessor :content

    include SetParams
    include Simple::Printer::Printable

    def initialize(entry)
      if entry.url
        begin
          uri = Addressable::URI.parse(entry.url.strip)
        rescue Addressable::URI::InvalidURIError => e
          raise Error, "Can't parse URL for entry: #{entry.url.inspect}"
        end
      else
        uri = nil
      end
      id = entry.entry_id || uri or raise Error, "Can't determine ID or URL for entry"
      super(
        id: id.to_s,
        uri: uri,
        date: entry.published || Time.now,
        title: entry.title,
        author: entry.respond_to?(:author) ? entry.author&.sub(/^by\s+/i, '') : nil,
        content: (entry.content || entry.summary)&.to_s,
      )
    end

    def printable
      [
        [:id, 'ID'],
        :date,
        :title,
        :uri,
        :author,
      ]
    end

    def eql?(other)
      @id.eql?(other.id)
    end

    def ==(other)
      @id == other&.id
    end

    def age
      Time.now - @date
    end

  end

end