module NewsFetcher

  class History

    def initialize(file)
      @file = Path.new(file)
      @entries = nil
    end

    def load
      if @file.exist?
        @entries = Hash[
          @file.readlines.map(&:chomp).reject(&:empty?).map { |l| l.split(/\s+/, 2) }.map do |timestamp, id|
            [id, Time.parse(timestamp)]
          end
        ]
      else
        @entries = {}
      end
    end

    def [](id)
      load unless @entries
      @entries[id]
    end

    def []=(id, timestamp)
      load unless @entries
      @file.open('a') do |io|
        @entries[id] = timestamp.to_s
        write(io, id: id, timestamp: timestamp)
      end
    end

    def write(io, id:, timestamp:)
      io.puts [timestamp.iso8601, id].join(' ')
    end

    def latest
      load unless @entries
      @entries.sort_by { |i, t| t }.last
    end

    def length
      load unless @entries
      @entries.length
    end

    def reset
      @entries = nil
      @file.unlink if @file.exist?
    end

    def prune(before: nil, after: nil)
      load unless @entries
      return if @entries.empty?
      @entries.delete_if do |id, timestamp|
        (before && timestamp < before) || (after && timestamp > after)
      end
      @file.open('w') do |io|
        @entries.each do |id, timestamp|
          write(io, id: id, timestamp: timestamp)
        end
      end
    end

  end

end