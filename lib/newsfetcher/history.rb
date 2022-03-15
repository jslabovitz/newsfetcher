module NewsFetcher

  class History

    attr_accessor :entries

    include SetParams

    def self.load(file)
      begin
        entries = JSON.parse(file.read).map { |id, time| [id, Time.parse(time)] }.to_h
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

    def prune(before:)
      @entries.delete_if { |id, time|
        t = (time < before)
        $logger.info { "pruning #{id.inspect} (#{time})"} if t
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

    def last_time
      @entries.values.sort.last
    end

  end

end