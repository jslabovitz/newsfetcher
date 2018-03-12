require 'date'
require 'path'
require 'uri'
require 'yaml'
require 'maildir'
require 'faraday'
require 'feedjira'
require 'hashstruct'
require 'nokogiri-plist'
require 'simple_option_parser'

require 'feeder/commands'
require 'feeder/profile'
require 'feeder/subscription'

module Feeder

  UserAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/604.1.25 (KHTML, like Gecko) Version/11.0 Safari/604.1.25'
  FeedDownloadTimeout = 30
  FeedDownloadFollowRedirectLimit = 5

  Feedjira.configure do |config|
    config.strip_whitespace = true
  end

  class Error < Exception; end

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

  def self.get(uri, if_modified_since: nil)
    headers = {
      user_agent: UserAgent,
    }
    headers.update(if_modified_since: if_modified_since.rfc2822) if if_modified_since
    request_options = {
      timeout: FeedDownloadTimeout,
    }
    begin
      connection = Faraday.new(url: uri, headers: headers, request: request_options) do |conn|
        conn.use(FaradayMiddleware::FollowRedirects, limit: FeedDownloadFollowRedirectLimit)
        conn.adapter(*Faraday.default_adapter)
      end
      connection.get
    rescue Faraday::Error, Zlib::BufError => e
      raise Error, "Failed to download resource from #{uri}: #{e}"
    end
  end

end