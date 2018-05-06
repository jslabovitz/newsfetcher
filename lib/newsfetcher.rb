require 'date'
require 'path'
require 'sdbm'
require 'uri'
require 'yaml'
require 'mail'
require 'maildir'
require 'faraday'
require 'feedjira'
require 'nokogiri-plist'
require 'simple-command'
require 'erb'

require 'newsfetcher/profile'
require 'newsfetcher/subscription'

require 'newsfetcher/command'
require 'newsfetcher/commands/dormant'
require 'newsfetcher/commands/fix'
require 'newsfetcher/commands/import'
require 'newsfetcher/commands/process'
require 'newsfetcher/commands/subscribe'
require 'newsfetcher/commands/update'

module NewsFetcher

  InfoFileName = 'info.yaml'
  DataFileName = 'feed'
  HistoryFileName = 'history'
  DownloadTimeout = 30
  DownloadFollowRedirectLimit = 5
  DataDir = '~/.newsfetcher'
  SubscriptionsDirName = 'subscriptions'
  StylesheetFile = Path.new(__FILE__).dirname / '../stylesheet.css'
  MessageTemplateFile = Path.new(__FILE__).dirname / '../message.rhtml'

  Feedjira.configure do |config|
    config.strip_whitespace = true
  end

  Maildir.serializer = Maildir::Serializer::Mail.new

  class Error < Exception; end

  def self.uri_to_key(uri)
    uri = URI.parse(uri)  unless uri.kind_of?(URI)
    [
      uri.host.to_s.sub(/^(www|ssl|en|feeds|blogs?|news).*?\./i, '').sub(/\.(com|org|net|info|edu|co\.uk)$/i, ''),
      uri.path.to_s.gsub(/\b(feed|atom|rss2|xml)\b/i, ''),
      uri.query.to_s.gsub(/(format|feed|type|q)=(atom|rss2?|xml|rss\.xml)/i, ''),
    ].reject(&:empty?).join('-').
      downcase.
      gsub(/[^a-z0-9]+/, ' ').  # non-alphanumeric
      strip.
      gsub(/\s+/, '-')
  end

  def self.get(uri, headers=nil)
    begin
      connection = Faraday.new(
        url: uri,
        headers: headers || {},
        request: { timeout: DownloadTimeout },
        ssl: { verify: false },
      ) do |conn|
        conn.use(FaradayMiddleware::FollowRedirects, limit: DownloadFollowRedirectLimit)
        conn.adapter(*Faraday.default_adapter)
      end
      response = connection.get
      if response.status == 304
        nil
      elsif response.success?
        response
      else
        raise Error, "Failed to get feed: #{response.status}"
      end
    rescue Faraday::Error, Zlib::BufError => e
      raise Error, "Failed to get #{uri}: #{e}"
    end
  end

end