# system

require 'date'
require 'digest'
require 'logger'
require 'yaml'

# gems

require 'addressable/uri'
require 'erb'
require 'faraday'
require 'feedjira'
require 'hashstruct'
require 'loofah'
require 'mail'
require 'nokogiri'
require 'path'
require 'rubypants'
require 'sassc'
require 'set_params'
require 'simple-builder'
require 'simple-command'

module NewsFetcher

  FeedFileName = 'feed.json'
  HistoryFileName = 'history.json'
  DownloadTimeout = 30
  DownloadFollowRedirectLimit = 5
  DefaultMaxThreads = 100
  DefaultDormantTime = 30 * 24 * 60 * 60    # one month
  DefaultProfileDir = '~/.newsfetcher'
  SubscriptionsDirName = 'subscriptions'
  MessageTemplateFile = Path.new(__FILE__).dirname / '../message/message.mail.erb'
  HTMLTemplateFile = Path.new(__FILE__).dirname / '../message/message.rhtml'
  StylesheetFile = Path.new(__FILE__).dirname / '../message/stylesheet.css'
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

require 'newsfetcher/extensions/addressable'
require 'newsfetcher/extensions/kernel'
require 'newsfetcher/extensions/string'

require 'newsfetcher/bundle'
require 'newsfetcher/error'
require 'newsfetcher/feed'
require 'newsfetcher/item'
require 'newsfetcher/mailer'
require 'newsfetcher/profile'
require 'newsfetcher/resource'
require 'newsfetcher/subscription'

require 'newsfetcher/command'
Path.new(__FILE__).dirname.glob('newsfetcher/commands/*.rb').each { |p| require p }