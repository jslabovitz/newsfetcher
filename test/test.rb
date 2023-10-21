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
      )
      @profile = Profile.new(dir: @dir, config: config)
      @profile.save
    end

    def test_run
      config_file = @dir / ConfigFileName
      config = BaseConfig.load(config_file)
      @profile = Profile.new(dir: @dir, config: config)
      # add web sites
      initial_subscriptions = [
        ['https://johnlabovitz.com', 'mine'],
        ['http://nytimes.com', 'news'],
        ['http://elpais.com', 'news', 'elpais'],
      ].map do |uri, path, id|
        uri = Addressable::URI.parse(uri)
        feeds = Resource.get(uri).feeds
        feed = feeds.first or raise "Can't discover feeds at #{uri}"
        uri = feed[:href] or raise "Can't find feed URI"
        subscription = @profile.add_subscription(uri: uri, id: id, path: path)
        assert { subscription }
        subscription
      end
      subscriptions = @profile.find_subscriptions
      assert { subscriptions.count == initial_subscriptions.count }
      # disable
      subscription = @profile.find_subscriptions(ids: %w[news/elpais]).first
      subscription.disable
      # update
      subscriptions.each { |s| @profile.update_subscription(s) }
      # find
      subscription = @profile.find_subscriptions(ids: %w[news/nytimes-services-nyt-homepage]).first
      assert { subscription.history_file.exist? }
    end

  end

end