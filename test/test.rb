$VERBOSE = false
# avoid annoying warning
class Object
  def tainted?; false; end
end

require 'minitest/autorun'
require 'minitest/power_assert'

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'newsfetcher'

module NewsFetcher

  class Test < Minitest::Test

    def setup
      @dir = Path.new('test/tmp/.newsfetcher')
      @dir.rmtree if @dir.exist?
      @msgs_dir = @dir / 'tmp/msgs'
      config = BaseConfig.make(
        mail_from: 'johnl@johnlabovitz.com',
        mail_to: 'johnl@johnlabovitz.com',
        log_level: :debug,
        # deliver_method: :file,
        # deliver_params: { location: @msgs_dir.to_s },
        deliver_method: :maildir,
        deliver_params: { location: @msgs_dir.to_s },
      )
      @profile = Profile.new(dir: @dir, config: config)
      @profile.save
      @profile = Profile.new(dir: @dir, config: config)
      @subscriptions = [
        ['https://johnlabovitz.com', 'tech'],
        ['http://nytimes.com', 'news', true],
      ].map do |uri, path, disable|
        feed = @profile.discover_feeds(uri).first
        id = Subscription.uri_to_id(feed.uri, path: path)
        @profile.add_subscription(uri: feed.uri, id: id, disable: disable)
      end
      @profile.update([])
    end

    def shutdown
      @subscriptions.each { |s| @profile.remove([s.id]) }
      @profile.reset([])
    end

    def test_show
      @profile.show([])
      @profile.show([], status: :active)
      @profile.show([], sort: :age)
      @profile.show([], details: true)
    end

  end

end