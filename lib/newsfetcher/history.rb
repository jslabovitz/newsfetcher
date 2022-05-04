module NewsFetcher

  class History

    attr_accessor :entries

    include SetParams

    def self.load(file)
      begin
        entries = JSON.parse(file.read).map { |key, time| [key, Time.parse(time)] }.to_h
      rescue JSON::ParserError => e
        raise Error, "Bad JSON file: #{file.to_s.inspect}: #{e}"
      end
      new(entries: entries)
    end

    def initialize(params={})
      @entries = {}
      set(params)
    end

    def save(file)
      file.write(JSON.pretty_generate(@entries))
    end

    def reset(file)
      @entries.clear
      save(file)
    end

    def prune(before:, &block)
      @entries.delete_if { |key, time|
        t = (time < before)
        yield(key, time) if t && block_given?
        t
      }
    end

    def include?(key)
      @entries[key] != nil
    end

    def [](key)
      @entries[key]
    end

    def []=(key, value)
      @entries[key] = value
    end

    def latest_entry
      @entries.sort_by { |k, v| v }.last
    end

  end

end