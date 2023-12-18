module NewsFetcher

  class Config

    class Error < StandardError; end

    attr_accessor :parent
    attr_accessor :fields
    attr_accessor :data

    def self.define(definitions)
      fields = {}
      defaults = {}
      definitions.each do |key, field|
        field = Field.make(field)
        fields[key] = field
        defaults[key] = field.convert(field.default)
      end
      new(fields: fields, data: {})
    end

    def initialize(parent: nil, fields:, data:)
      @parent = parent
      @fields = fields
      @data = data.map do |key, value|
        field = @fields[key] or raise Error, "Unknown config key: #{key.inspect}"
        [key, field.convert(value)]
      end.to_h
    end

    def load(file)
      make(**JSON.parse(file.read, symbolize_names: true))
    end

    def make(**data)
      self.class.new(parent: self, fields: @fields, data: data)
    end

    def as_json(*opts)
      @data.compact
    end

    def to_json(*opts)
      as_json.to_json(*opts)
    end

    def save(file)
      file.write(JSON.pretty_generate(self))
    end

    def method_missing(id, *args)
      key = id.to_s.sub(/=$/, '').to_sym
      field = @fields[key] or return super
      if $&
        @data[key] = args.first
      elsif @data.has_key?(key)
        @data[key]
      elsif @parent
        @parent.send(key)
      else
        field.default
      end
    end

    class Field

      attr_accessor :default
      attr_accessor :converter

      def self.make(obj)
        case obj
        when nil
          new
        when Proc
          new(converter: obj)
        when Hash
          new(**obj)
        when Field
          obj
        else
          new(default: obj)
        end
      end

      def initialize(default: nil, converter: nil)
        @default = default
        @converter = converter
      end

      def convert(value)
        case @converter
        when Symbol
          value&.send(@converter)
        when Proc
          @converter.call(value)
        else
          value
        end
      end

    end

  end

end