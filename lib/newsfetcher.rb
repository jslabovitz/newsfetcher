# system

require 'logger'
require 'ostruct'

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
  ItemHistoryFileName = 'item_history.jsonl'
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
require 'newsfetcher/extensions/mail'
require 'newsfetcher/extensions/addressable-uri'

require 'newsfetcher/config'
require 'newsfetcher/error'
require 'newsfetcher/fetcher'
require 'newsfetcher/history'
require 'newsfetcher/item'
require 'newsfetcher/profile'
require 'newsfetcher/scrubber'
require 'newsfetcher/subscription'

module NewsFetcher

  DaySecs = 24 * 60 * 60
  BaseConfig = Config.define(
    max_threads: 100,
    log_level: { default: :warn, converter: proc { |o| o.downcase.to_sym } },
    max_age: 30 * DaySecs,
    main_stylesheet: File.join(File.dirname(__FILE__), '../message/stylesheet.css'),
    aux_stylesheets: nil,
    delivery_method: { converter: :to_sym },
    delivery_params: { default: {} },
    mail_from: nil,
    mail_to: nil,
    mail_subject: '[<%= subscription_id %>] <%= item_title %>',
    uri: proc { |o| Addressable::URI.parse(o) },
    title: nil,
    disabled: false,
    ignore_uris: { default: [], converter: proc { |o| [o].flatten.compact.map { |r| Regexp.new(r) } } },
    ignore_moved: false,
    root_folder: nil,
    consolidate: false,
  )

end

require 'newsfetcher/command'
Path.new(__FILE__).dirname.glob('newsfetcher/commands/*.rb').each { |p| require p }