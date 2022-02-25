module NewsFetcher

  class Feed

    attr_reader   :uri
    attr_accessor :title
    attr_reader   :items

    include SetParams

    def self.load(file)
      new.tap { |f| f.set(JSON.parse(file.read)) }
    end

    def self.new_from_resource(resource)
      Feedjira.configure { |c| c.strip_whitespace = true }
      begin
        feedjira = Feedjira.parse(resource.content.force_encoding(Encoding::UTF_8))
      rescue => e
        raise Error, "Can't parse XML feed from #{uri}: #{e}"
      end
      new(
        uri: resource.uri,
        title: feedjira.title,
        items: feedjira.entries.map { |entry|
          item = Item.new(
            id: entry.entry_id || entry.url,
            date: entry.published || Time.now,
            title: entry.title,
            uri: entry.url,
            author: entry.respond_to?(:author) ? entry.author : nil,
            content: entry.content || entry.summary || '',
          )
          [item.id, item]
        }.to_h,
      )
    end

    def initialize(params={})
      @items = {}
      set(params)
    end

    def uri=(uri)
      @uri = Addressable::URI.parse(uri)
    end

    def items=(items)
      @items = case items
      when Array
        items.map { |item|
          item = item.kind_of?(Item) ? item : Item.new(item)
          [item.id, item]
        }.to_h
      when Hash
        items.map { |id, item|
          item = item.kind_of?(Item) ? item : Item.new(item)
          [id, item]
        }.to_h
      end
    end

    def to_h
      {
        uri: @uri,
        title: @title,
        items: @items.values,
      }
    end

    def as_json(*options)
      to_h.compact
    end

    def to_json(*options)
      as_json(*options).to_json(*options)
    end

    def save(file)
      file.write(JSON.pretty_generate(self))
    end

    def last_item_date
      @items.values.map(&:date).sort.last
    end

  end

end