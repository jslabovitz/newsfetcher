require 'date'
require 'logger'
require 'yaml'

require 'addressable/uri'
require 'faraday'
require 'feedjira'
require 'hashstruct'
require 'loofah'
require 'mail'
require 'nokogiri'
require 'path'
require 'sassc'
require 'set_params'
require 'simple-command'

module NewsFetcher

  FeedFileName = 'feed.json'
  DownloadTimeout = 30
  DownloadFollowRedirectLimit = 5
  DefaultMaxThreads = 100
  DefaultDormantTime = 30 * 24 * 60 * 60    # one month
  DefaultProfileDir = '~/.newsfetcher'
  SubscriptionsDirName = 'subscriptions'
  StylesheetFile = Path.new(__FILE__).dirname / '../message/stylesheet.css'

end

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

module Kernel

  def silence_warnings(&block)
    warn_level = $VERBOSE
    $VERBOSE = nil
    result = block.call
    $VERBOSE = warn_level
    result
  end

end

class String

  def replace_fields(fields)
    gsub(/%(\w)/) do
      raise "Unknown tag: #{$1.inspect}" unless fields.has_key?($1)
      fields[$1] || ''
    end
  end

end