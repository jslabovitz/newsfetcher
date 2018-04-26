require 'date'
require 'path'
require 'uri'
require 'yaml'
require 'mail'
require 'maildir'
require 'faraday'
require 'feedjira'
require 'nokogiri-plist'
require 'simple-command'

require 'newsfetcher/profile'
require 'newsfetcher/feed'

require 'newsfetcher/command'
require 'newsfetcher/commands/add'
require 'newsfetcher/commands/dormant'
require 'newsfetcher/commands/fix'
require 'newsfetcher/commands/import'
require 'newsfetcher/commands/update'

module NewsFetcher

  FeedInfoFileName = 'info.yaml'
  FeedDataFileName = 'feed'
  FeedHistoryFileName = 'history'
  FeedDownloadTimeout = 30
  FeedDownloadFollowRedirectLimit = 5
  DefaultDataDir = '~/.newsfetcher'
  StylesheetFile = Path.new(__FILE__).dirname / '../stylesheet.css'

  Feedjira.configure do |config|
    config.strip_whitespace = true
  end

  Maildir.serializer = Maildir::Serializer::Mail.new

  class Error < Exception; end

  def self.uri_to_key(uri)
    uri = URI.parse(uri)  unless uri.kind_of?(URI)
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

  def self.get(uri, if_modified_since: nil)
    headers = {}
    headers[:if_modified_since] = if_modified_since.rfc2822 if if_modified_since
    begin
      connection = Faraday.new(
        url: uri,
        headers: headers,
        request: { timeout: FeedDownloadTimeout },
        ssl: { verify: false },
      ) do |conn|
        conn.use(FaradayMiddleware::FollowRedirects, limit: FeedDownloadFollowRedirectLimit)
        conn.adapter(*Faraday.default_adapter)
      end
      connection.get
    rescue Faraday::Error, Zlib::BufError => e
      raise Error, "Failed to download resource from #{uri}: #{e}"
    end
  end

end