# system

require 'date'
require 'logger'

# gems

require 'addressable/uri'
require 'addressable-prettify'
require 'erb'
require 'faraday'
require 'feedjira'
require 'loofah'
require 'mail'
require 'maildir'
require 'nokogiri'
require 'path'
require 'pragmatic_segmenter'
require 'rubypants'
require 'sassc'
require 'set_params'
require 'simple-builder'
require 'simple-command'
require 'simple-printer'
require 'twitter'

module NewsFetcher

  ConfigFileName = 'config.json'
  HistoryFileName = 'history.json'
  DefaultProfileDir = '~/.newsfetcher'
  SubscriptionsDirName = 'subscriptions'
  # see https://stackoverflow.com/questions/595616/what-is-the-correct-mime-type-to-use-for-an-rss-feed
  # ordered by preference
  FeedTypes = %w[
    application/atom+xml
    application/rss+xml
    application/rdf+xml
    text/atom+xml
    text/rss+xml
    text/rdf+xml
    application/xml
    text/xml
  ]
end

require 'newsfetcher/extensions/kernel'
require 'newsfetcher/extensions/string'

require 'newsfetcher/config'
require 'newsfetcher/error'
require 'newsfetcher/history'
require 'newsfetcher/profile'
require 'newsfetcher/resource'
require 'newsfetcher/scrubbers'
require 'newsfetcher/subscriptions/base'
require 'newsfetcher/subscriptions/feed'
require 'newsfetcher/subscriptions/twitter'

module NewsFetcher

  BaseConfig = Config.new(
    max_threads: 100,
    log_level: :warn,
    dormant_time: 30 * 24 * 60 * 60,    # one month
    main_stylesheet: File.join(File.dirname(__FILE__), '../message/stylesheet.css'),
    mail_subject: '[<%= subscription_id %>] <%= item_title %>',
  )

end

require 'newsfetcher/command'
Path.new(__FILE__).dirname.glob('newsfetcher/commands/*.rb').each { |p| require p }