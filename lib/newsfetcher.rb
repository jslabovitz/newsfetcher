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
require 'simple-command'

require 'newsfetcher/bundle'
require 'newsfetcher/error'
require 'newsfetcher/history'
require 'newsfetcher/item'
require 'newsfetcher/profile'
require 'newsfetcher/subscription'

module NewsFetcher

  FeedFileName = 'feed'
  HistoryFileName = 'history'
  DownloadTimeout = 30
  DownloadFollowRedirectLimit = 5
  DefaultMaxThreads = 100
  DefaultDormantTime = 30 * 24 * 60 * 60    # one month
  DefaultProfileDir = '~/.newsfetcher'
  SubscriptionsDirName = 'subscriptions'
  StylesheetFile = Path.new(__FILE__).dirname / '../message/stylesheet.css'

  def self.verify_uri!(uri)
    raise Error, "Invalid URI: #{uri}" unless uri.absolute? && uri.scheme && uri.host
  end

  def self.get(uri, if_modified_since: nil)
    resp = {}
    headers = {}
    headers[:if_modified_since] = if_modified_since.rfc2822 if if_modified_since
    redirects = 0
    loop do
      connection = Faraday.new(
        url: uri,
        headers: headers,
        request: { timeout: DownloadTimeout },
        ssl: { verify: false })
      begin
        response = connection.get
      rescue Faraday::ConnectionFailed => e
        raise Error, "Couldn't connect to #{uri}: #{e.message} [#{e.class}]"
      rescue StandardError => e
        raise Error, "Couldn't get #{uri}: #{e.message} [#{e.class}]"
      end
      case response.status
      when 200...300
        resp[:status] = :loaded
        resp[:content] = response.body
        resp[:last_modified] = Time.parse(response.headers[:last_modified] || response.headers[:date])
        break
      when 304
        resp[:status] = :not_modified
        break
      when 300...400
        new_uri = uri.join(Addressable::URI.parse(response.headers[:location]))
        begin
          verify_uri!(new_uri)
        rescue Error => e
          resp[:status] = :failed
          resp[:message] = "Bad redirected URI: #{new_uri}"
          break
        end
        redirects += 1
        if redirects > DownloadFollowRedirectLimit
          resp[:status] = :failed
          resp[:message] = "Too many redirects"
          break
        end
        resp[:redirect] = new_uri if response.status == 301
        uri = new_uri
      when 400..600
        resp[:status] = :failed
        resp[:message] = "Server error: #{response.status}"
      else
        resp[:status] = :failed
        resp[:message] = "Unexpected status: #{response.status}"
      end
    end
    resp
  end

end