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
      @site_uri = 'http://rubyweekly.com'
      @feed_uri = 'http://rubyweekly.com/rss/'
      @email = 'johnl@johnlabovitz.com'
      @log_level = :error
      @dir.rmtree if @dir.exist?
      Profile.init(@dir,
        mail_from: @email,
        mail_to: @email,
        log_level: @log_level)
      @profile = Profile.new(
        dir: @dir,
        log_level: @log_level)
      @subscription = @profile.add_subscription(
        uri: @feed_uri,
        path: 'tech')
    end

    def shutdown
    end

    def test_show
      @profile.show([])
      @profile.show([], status: :active)
      @profile.show([], sort: :title)
      @profile.show([], details: true)
    end

    def test_discover
      @profile.discover_feed(@site_uri)
    end

    def test_update
      @profile.update([])
    end

    def test_remove
      @profile.remove([@subscription.id])
    end

    def test_reset
      @profile.reset([])
    end

  end

end