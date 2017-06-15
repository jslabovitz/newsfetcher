module Feeder

  def self.save_json(object, file)
    file.dirname.mkpath unless file.dirname.exist?
    file.open('w') { |io| io.write(JSON.pretty_generate(object)) }
  end

  def self.load_json(file)
    JSON.parse(file.read)
  end

  def self.object_to_hash(from_obj, translation_map)
    hash = {}
    translation_map.each do |item|
      from_method, to_method = case item
      when Hash
        [item.keys.first, item.values.first]
      when String, Symbol
        [item, item]
      else
        raise "Bad element in translation map: #{item.inspect}"
      end
      from_method = from_method.to_sym
      to_method = to_method.to_s
      if from_obj.respond_to?(from_method) && (value = from_obj.send(from_method))
        # ;;pp(value: value)
        if value.kind_of?(String)
          value.strip!
          value = nil if value.empty?
        end
        hash[to_method] = value if value
      end
    end
    hash
  end

end