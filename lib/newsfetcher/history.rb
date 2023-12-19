module NewsFetcher

  class History

    attr_accessor :file
    attr_accessor :entries

    def initialize(file:, index_key: nil)
      @file = Path.new(file)
      @entries = []
      @index = {}
      @index_key = index_key
      if @file.exist?
        load_entries
      else
        @file.touch
      end
    end

    def load_entries
      @file.readlines.map do |line|
        add_entry(Entry.from_json(line))
      end
    end

    def <<(entry)
      entry = Entry.new(**entry) if entry.kind_of?(Hash)
      add_entry(entry)
      @file.open('a') { |io| io.puts entry.to_json }
    end

    def [](key)
      raise "No index_key defined" unless @index_key
      @index[key]
    end

    def size
      @entries.size
    end

    def last_entry
      @entries.last
    end

    def prune(before:)
      old = @entries.select { |e| e.time < before }
      old.each { |e| delete_entry(e) }
      save_entries
      old
    end

    def reset
      @entries = []
      @index = {}
      @file.unlink
    end

    private

    def save_entries
      new_file = @file.add_extension('.new')
      new_file.open('w') do |io|
        @entries.each { |e| io.puts e.to_json }
      end
      @file.unlink
      new_file.rename(@file)
    end

    def add_entry(entry)
      @entries << entry
      @index[entry[@index_key]] = entry if @index_key
    end

    def delete_entry(entry)
      @entries.delete(entry)
      @index.delete(entry[@index_key]) if @index_key
    end

    class Entry < OpenStruct

      def self.from_json(data)
        json = JSON.parse(data, symbolize_names: true)
        self.parse_json(json)
        new(**json)
      end

      def self.parse_json(json)
        json[:time] = Time.at(json[:time])
      end

      def to_json(*opts)
        h = to_h
        h[:time] = h[:time].to_i
        h.to_json(*opts)
      end

    end

  end

end