module NewsFetcher

  class History

    attr_accessor :file
    attr_accessor :entries

    include SetParams

    def self.load(file:, **params)
      new(file: file, entries: JSON.parse(file.read, object_class: HashStruct))
    end

    def initialize(params={})
      @entries = HashStruct.new
      set(params)
    end

    def save
      @file.write(JSON.pretty_generate(@entries))
    end

    def reset
      @entries.clear
      save
    end

    def prune(before:)
      @entries.delete_if { |id, date| date > before }
    end

    def has_key?(key)
      @entries.has_key?(key)
    end

    def [](key)
      @entries[key]
    end

    def []=(key, value)
      @entries[key] = value
    end

  end

end