module NewsFetcher

  class Feed

    attr_reader   :uri
    attr_accessor :title
    attr_reader   :items

    include SetParams

    def self.load(file)
      new.tap { |f| f.set(JSON.parse(file.read)) }
    end

    def self.get(uri)
      resource = Resource.get(uri)
      Feedjira.configure { |c| c.strip_whitespace = true }
      begin
        feedjira = Feedjira.parse(resource.content.force_encoding(Encoding::UTF_8))
      rescue => e
        raise Error, "Can't parse XML feed: #{e}"
      end
      new(
        uri: uri,
        title: feedjira.title,
        items: feedjira.entries.map { |entry|
          Item.new(
            id: entry.entry_id || entry.url,
            date: entry.published || Time.now,
            title: entry.title,
            uri: entry.url,
            author: entry.respond_to?(:author) ? entry.author : nil,
            content: entry.content || entry.summary || '',
          )
        },
      )
    end

    def initialize(params={})
      @items = []
      set(params)
    end

    def uri=(uri)
      @uri = Addressable::URI.parse(uri)
    end

    def items=(items)
      @items = items.map { |item| item.kind_of?(Item) ? item : Item.new(item) }
    end

    def to_h
      {
        uri: @uri,
        title: @title,
        items: @items,
      }
    end

    def as_json(*options)
      to_h.compact
    end

    def to_json(*options)
      as_json(*options).to_json(*options)
    end

    def items_hash
      @items.map { |i| [i.id, i] }.to_h
    end

    def merge!(other, remove_dormant:, ignore:)
      @items.each { |i| i.is_new = false }
      this = items_hash
      other = other.items_hash
      new_ids = other.keys - this.keys
      new_ids.each do |id|
        new_item = other[id]
        new_item.is_new = true
        @items << new_item
      end
      @items.delete_if do |item|
        (remove_dormant && item.age > remove_dormant) ||
        (ignore && ignore.find { |r| item.uri.to_s =~ r })
      end
      @items.sort_by!(&:date)
    end

    def save(file)
      file.write(JSON.pretty_generate(self))
    end

    def new_items
      @items.select(&:is_new)
    end

    def last_item_date
      @items.map(&:date).sort.last
    end

  end

end