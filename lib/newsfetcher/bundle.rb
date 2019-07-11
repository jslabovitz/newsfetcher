module NewsFetcher

  class Bundle

    InfoFilename = 'info.yaml'

    attr_accessor :dir
    attr_accessor :info_file
    attr_accessor :info

    def self.bundles(dir, info_filename=InfoFilename)
      dir.glob("**/#{info_filename}").map(&:dirname).map do |bundle_dir|
        new(bundle_dir)
      end
    end

    def initialize(dir, info_filename=InfoFilename)
      @dir = Path.new(dir).expand_path
      @info_file = @dir / info_filename
      if @info_file.exist?
        @info = HashStruct.new(YAML.load(@info_file.read))
      else
        @info = HashStruct.new
      end
    end

    def to_hash
      Hash[
        @info.select { |k, v| v }.map { |k, v| [k.to_s, v.to_s] }
      ]
    end

    def save
      @dir.mkpath unless @dir.exist?
      @info_file.write(to_hash.to_yaml(line_width: -1))
    end

    def reset
      @info = HashStruct.new
      @info_file.unlink if @info_file.exist?
    end

  end

end