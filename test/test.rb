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

    def add_subscription(uri:, path:, **options)
      feed = @profile.discover_feeds(uri).first
      id = Subscription.uri_to_id(feed.uri, path: path)
      @profile.add_subscription(
        uri: feed.uri,
        id: id,
        **options)
    end

    def setup
      @dir = Path.new('test/.newsfetcher')
      @dir.rmtree if @dir.exist?
      @msgs_dir = @dir / 'msgs'
      @profile = Profile.init(@dir,
        mail_from: 'johnl@johnlabovitz.com',
        mail_to: 'johnl@johnlabovitz.com',
        log_level: :debug,
        deliver_method: :file,
        deliver_params: { location: @msgs_dir.to_s },
      )
      @profile.save
      @profile = Profile.new(dir: @dir)
      @subscriptions = [
        add_subscription(uri: 'https://johnlabovitz.com', path: 'tech'),
        add_subscription(uri: 'http://nytimes.com', path: 'news', disable: true),
      ]
      @profile.update([])
    end

    def shutdown
      @subscriptions.each { |s| @profile.remove([s.id]) }
      @profile.reset([])
    end

    def test_show
      @profile.show([])
      @profile.show([], status: :active)
      @profile.show([], sort: :title)
      @profile.show([], details: true)
    end

  end

end