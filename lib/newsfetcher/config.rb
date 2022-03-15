module NewsFetcher

  class Config

    attr_accessor :parent
    attr_accessor :hash

    def self.load(file)
      new(JSON.parse(file.read, symbolize_names: true))
    end

    def initialize(params={})
      @hash = params
    end

    def ==(other)
      @hash == other.hash
    end

    def load(file)
      self.class.load(file).tap { |c| c.parent = self }
    end

    def make(params={})
      self.class.new(params).tap { |c| c.parent = self }
    end

    def save(file)
      file.dirname.mkpath unless file.dirname.exist?
      file.write(JSON.pretty_generate(@hash))
    end

    def merged
      (@parent&.merged || {}).merge(@hash)
    end

    def method_missing(id, *args)
      if (key = id.to_s).sub!(/=$/, '')
        @hash[key.to_sym] = args.first
      else
        if @hash.has_key?(id)
          @hash[id]
        elsif @parent
          @parent.send(id, *args)
        else
          nil
        end
      end
    end

  end

end