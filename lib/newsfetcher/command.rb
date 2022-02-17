module NewsFetcher

  class Command < SimpleCommand::Command

    def run(args)
      super
      @profile = Profile.new(
        dir: @dir,
        log_level: @log_level,
        max_threads: @max_threads,
      ) or raise Error, "Profile not loaded"
    end

  end

end