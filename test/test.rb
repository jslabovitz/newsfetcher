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
      @dir = Path.new('test/.newsfetcher')
      @dir.rmtree if @dir.exist?
      @profile = Profile.init(@dir,
        mail_from: 'johnl@johnlabovitz.com',
        mail_to: 'johnl@johnlabovitz.com',
        log_level: :error)
      @profile.save
      @profile = Profile.new(dir: @dir)
      feeds = @profile.discover_feed('https://johnlabovitz.com')
      feed = feeds.find { |f| f[:type] == 'application/atom+xml' }
      id = Subscription.uri_to_id(feed[:uri], path: 'tech')
      @subscription = @profile.add_subscription(
        uri: feed[:uri],
        id: id)
      @profile.update([])
    end

    def shutdown
      @profile.remove([@subscription.id])
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