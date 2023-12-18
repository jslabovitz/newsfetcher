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
      @dir.mkpath
      @msgs_dir = @tmp_dir / 'msgs'
      config_file = @dir / ConfigFileName
      config = BaseConfig.make(
        mail_from: 'newsfetcher',
        mail_to: 'johnl',
        log_level: :debug,
        root_folder: 'News',
        delivery_method: :maildir,
        delivery_params: { dir: @msgs_dir.to_s },
      )
      config.save(config_file)
    end

    def test_run
      config_file = @dir / ConfigFileName
      config = BaseConfig.load(config_file)
      @profile = Profile.new(dir: @dir, config: config)
      # add web sites
      initial_subscriptions = [
        ['https://johnlabovitz.com', 'mine'],
        ['http://nytimes.com', 'world'],
        ['http://elpais.com', 'world', 'elpais'],
      ].map do |uri, path, id|
        feeds = Fetcher.find_feeds(uri)
        assert { feeds.count == 1 }
        feed = feeds.first
        assert { feed }
        uri = feed[:uri]
        assert { uri }
        dir = @profile.add_subscription(uri: uri, id: id, path: path)
        assert { dir.exist? }
        dir
      end
      subscriptions = @profile.find_subscriptions
      assert { subscriptions.count == initial_subscriptions.count }
      # update
      subscriptions.each(&:update)
      # find
      subscription = @profile.find_subscriptions(ids: %w[world/nytimes-services-nyt-homepage]).first
      assert { subscription.history_file.exist? }
    end

  end

end