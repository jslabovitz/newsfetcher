module NewsFetcher

  class Bundle

    InfoFilename = 'info.yaml'

    attr_accessor :dir
    attr_accessor :info_file
    attr_accessor :info

    def self.bundles(dir:, ids: nil)
      if ids.nil? || ids.empty?
        dirs = dir.glob("**/#{InfoFilename}").map(&:dirname)
      else
        dirs = ids.map { |id| dir / id }
      end
      dirs.map do |bundle_dir|
        raise Error, "Bundle not found: #{bundle_dir.inspect}" unless bundle_dir.exist?
        new(bundle_dir)
      end
    end

    def initialize(dir)
      @dir = Path.new(dir).expand_path
      @info_file = @dir / InfoFilename
      if @info_file.exist?
        @info = HashStruct.new(YAML.load(@info_file.read))
      else
        @info = HashStruct.new
      end
    end

    def to_hash
      Hash[
        @info.select { |k, v| v }.map { |k, v| [k.to_s, v] }
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