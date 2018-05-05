module NewsFetcher

  class Command < SimpleCommand

    attr_accessor :profile

    def profile=(name)
      @profile = Profile.load(Path.new(DataDir, name).expand_path)
    end

  end

end