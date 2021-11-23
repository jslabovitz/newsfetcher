module NewsFetcher

  class Command < SimpleCommand::Command

    def self.defaults
      super.merge(
        dir: NewsFetcher::DefaultProfileDir,
        log_level: nil,
      )
    end

    def run(args)
      super
      @dir = Path.new(@dir)
      @profile = Profile.new(dir: @dir, log_level: @log_level && @log_level.downcase.to_sym) \
        or raise Error, "Profile not loaded"
    end

  end

end