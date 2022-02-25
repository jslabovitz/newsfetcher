module NewsFetcher

  class Config

    attr_accessor :parent
    attr_accessor :hash

    def self.load(file)
      new(JSON.load(file.read))
    end

    def initialize(params={})
      @hash = HashStruct.new(params)
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

    def method_missing(method_id, *args)
      if @hash.has_key?(method_id)
        @hash.send(method_id, *args)
      elsif @parent
        @parent.send(method_id, *args)
      else
        nil
      end
    end

  end

end