module NewsFetcher

  class Command < Simple::CommandParser::Command

    attr_accessor :dir
    attr_accessor :log_level
    attr_accessor :max_threads

    def run(args)
      dir = Path.new(@dir || DefaultProfileDir)
      config_file = dir / ConfigFileName
      config = config_file.exist? ? BaseConfig.load(config_file) : BaseConfig.make
      config.log_level = @log_level.downcase.to_sym if @log_level
      config.max_threads = @max_threads&.to_i if @max_threads
      @profile = Profile.new(dir: dir, config: config) or raise Error, "Profile not loaded"
    end

  end

end