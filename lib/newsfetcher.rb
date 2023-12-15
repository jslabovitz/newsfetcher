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
require 'rubypants'
require 'sassc'
require 'set_params'
require 'simple-builder'
require 'simple-command'
require 'simple-printer'

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
require 'newsfetcher/formatter'
require 'newsfetcher/history'
require 'newsfetcher/item'
require 'newsfetcher/profile'
require 'newsfetcher/fetcher'
require 'newsfetcher/subscription'

module NewsFetcher

  DaySecs = 24 * 60 * 60
  BaseConfig = Config.new(
    max_threads: 100,
    log_level: :warn,
    max_age: 30 * DaySecs,
    main_stylesheet: File.join(File.dirname(__FILE__), '../message/stylesheet.css'),
    # aux_stylesheets: nil,
    # delivery_method: nil,
    # delivery_params: nil,
    # mail_from: nil,
    # mail_to: nil,
    mail_subject: '[<%= subscription_id %>] <%= item_title %>',
    # uri: nil,
    # title: nil,
    # disabled: false,
    # ignore_uris: nil,
    # ignore_moved: false,
    # root_folder: nil,
    # consolidate: false,
  )

end

require 'newsfetcher/command'
Path.new(__FILE__).dirname.glob('newsfetcher/commands/*.rb').each { |p| require p }