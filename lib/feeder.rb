require 'date'
require 'path'
require 'uri'
require 'yaml'
require 'maildir'
require 'feedjira'
require 'hashstruct'
require 'nokogiri-plist'
require 'simple_option_parser'

require 'feeder/commands'
require 'feeder/profile'
require 'feeder/subscription'

module Feeder

  FeedFile = 'feed.xml'
  InfoFile = 'info.yaml'
  SubscriptionsDir = '~/.feeds'
  SubscriptionsFile = '~/Library/Application Support/NetNewsWire/Subscriptions.plist'
  MailDir = '~/Mail/jlabovitz'

  class Error < Exception; end

  def self.subscriptions_dir
    @subscriptions_dir ||= Path.new(SubscriptionsDir).expand_path
  end

  def self.subscriptions_file
    @subscriptions_file ||= Path.new(SubscriptionsFile).expand_path
  end

  def self.uri_to_key(uri)
    uri = URI.parse(uri)
    [
      uri.host.to_s.sub(/^(www|ssl|en|feeds|blogs?|news).*?\./i, '').sub(/\.(com|org|net|info|edu|co\.uk)$/, ''),
      uri.path.to_s.gsub(/\b(feed|atom|rss2|xml)\b/i, ''),
      uri.query.to_s.gsub(/(format|feed|type|q)=(atom|rss2?|xml|rss\.xml)/i, ''),
    ].reject { |s| s.empty? }.join('-').
      downcase.
      gsub(//, '').
      gsub(/[^a-z0-9]+/, ' ').  # non-alphanumeric
      strip.
      gsub(/\s+/, '-')
    end

end