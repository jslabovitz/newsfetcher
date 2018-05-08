module NewsFetcher

  class Command < SimpleCommand

    attr_accessor :profile
    attr_accessor :profiles

    def initialize(params={})
      super
      @profiles = if @profiles
        @profiles.split(',')
      elsif @profile
        [@profile]
      else
        DataDir.children.select(&:directory?)
      end
      @profiles = @profiles.map { |p| Profile.load(DataDir / p) }
    end

  end

end