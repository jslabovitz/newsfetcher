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
        mail_from: 'newsfetcher',
        mail_to: 'johnl',
        log_level: :error,
        deliver_method: :maildir,
        deliver_params: {
          location: @msgs_dir.to_s,
          folder: 'News'
        },
        consolidate: false,
      )
      @profile = Profile.new(dir: @dir, config: config)
      @profile.save
    end

    def test_run
      config_file = @dir / ConfigFileName
      config = BaseConfig.load(config_file)
      @profile = Profile.new(dir: @dir, config: config)
      # add web sites
      specs = [
        ['https://johnlabovitz.com', 'mine'],
        ['http://nytimes.com', 'news'],
        ['http://elpais.com', 'news', 'elpais'],
      ].map do |uri, path, id|
        uri = Addressable::URI.parse(uri)
        feeds = Resource.get(uri).feeds
        feed = feeds.first or raise "Can't discover feeds at #{uri}"
        feed_uri = feed[:href] or raise "Can't find feed URI"
        subscription = Subscriptions::Feed::Subscription.new(
          id: Subscriptions::Feed::Subscription.make_id(uri: feed_uri, id: id, path: path),
          config: Config.new(uri: feed_uri))
        @profile.add_subscription(subscription)
      end
      subscriptions = @profile.find_subscriptions
      assert { subscriptions.count == specs.count }
      # disable
      subscription = @profile.find_subscriptions(ids: %w[news/elpais]).first
      subscription.disable
      # update
      subscriptions.each(&:update)
      # find
      subscription = @profile.find_subscriptions(ids: %w[news/nytimes-services-nyt-homepage]).first
      assert { subscription.history_file.exist? }
    end

  end

end