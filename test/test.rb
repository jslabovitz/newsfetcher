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
      @tmp_dir = Path.new('test/tmp')
      @tmp_dir.rmtree if @tmp_dir.exist?
      @dir = @tmp_dir / 'newsfetcher'
      @msgs_dir = @tmp_dir / 'msgs'
      config = BaseConfig.make(
        mail_from: 'johnl@johnlabovitz.com',
        mail_to: 'johnl@johnlabovitz.com',
        log_level: :error,
        deliver_method: :maildir,
        deliver_params: { location: @msgs_dir.to_s },
      )
      @profile = Profile.new(dir: @dir, config: config)
      @profile.save
    end

    # def shutdown
    #   @subscriptions.each { |s| @profile.remove([s.id]) }
    #   @profile.reset([])
    # end

    def test_run
      config_file = @dir / ConfigFileName
      config = BaseConfig.load(config_file)
      @profile = Profile.new(dir: @dir, config: config)
      @subscriptions = [
        ['https://johnlabovitz.com', 'mine'],
        ['http://nytimes.com', 'news'],
        ['https://www.theguardian.com', 'news', true],
      ].map do |uri, path, disable|
        subscription = Subscription.discover_feeds(uri, path: path).first
        subscription.config.disable = disable
        @profile.add_subscription(subscription)
      end
      @profile.update([])
      found_subscription = @profile.find_subscriptions(ids: %w[news/nytimes-services-nyt-homepage]).first
      assert { found_subscription.history_file.exist? }
      @profile.show([])
      @profile.show([], status: :active)
      @profile.show([], sort: :age)
      @profile.show([], details: true)
    end

  end

end