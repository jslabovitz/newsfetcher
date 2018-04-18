module NewsFetcher

  class Command < SimpleCommand

    attr_accessor :profile

    def profile=(name)
      @profile = Profile.load(Path.new(DefaultDataDir, name).expand_path)
    end

  end

end