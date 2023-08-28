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
        deliver_method: :test,
        deliver_params: { location: @msgs_dir.to_s },
      )
      @profile = Profile.new(dir: @dir, config: config)
      @profile.save
    end

    def test_run
      config_file = @dir / ConfigFileName
      config = BaseConfig.load(config_file)
      @profile = Profile.new(dir: @dir, config: config)
      # add web sites
      @subscriptions = [
        ['https://johnlabovitz.com', 'mine'],
        ['http://nytimes.com', 'news'],
        ['http://elpais.com', 'news', true],
      ].map do |uri, path, disable|
        subscriptions = Subscriptions::Feed::Subscription.discover_feeds(uri, path: path)
        subscription = subscriptions.first or raise "Can't discover feeds at #{uri}"
        subscription.config.disable = disable
        @profile.add_subscription(subscription)
      end
      # update
      @profile.find_subscriptions.each(&:update)
      @msgs_dir.mkpath
      Mail::TestMailer.deliveries.each_with_index do |mail, i|
        base = @msgs_dir / ('%04d' % i)
        base.add_extension('.eml').write(mail)
        base.add_extension('.html').write(mail.body)
      end
      found_subscription = @profile.find_subscriptions(ids: %w[news/nytimes-services-nyt-homepage]).first
      assert { found_subscription.history_file.exist? }
    end

  end

end