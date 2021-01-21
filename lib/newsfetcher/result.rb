module NewsFetcher

  class Result

    attr_accessor :location
    attr_accessor :type
    attr_accessor :reason
    attr_accessor :status
    attr_accessor :headers
    attr_accessor :content

    include SetParams

    def self.load(file)
      raise Error, "No result file" unless file.exist?
      new(JSON.parse(file.read))
    end

    def location=(location)
      @location = Addressable::URI.parse(location)
    end

    def type=(type)
      @type = type.to_sym
    end

    def to_hash
      {
        location: @location,
        type: @type,
        reason: @reason,
        status: @status,
        headers: @headers,
        content: @content,
      }
    end

    def save(file)
      file.write(JSON.pretty_generate(to_hash))
    end

  end

end