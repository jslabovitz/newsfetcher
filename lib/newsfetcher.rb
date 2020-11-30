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

  ResultFileName = 'result.json'
  HistoryFileName = 'history'
  DownloadTimeout = 30
  DownloadFollowRedirectLimit = 5
  DefaultMaxThreads = 100
  DefaultDormantTime = 30 * 24 * 60 * 60    # one month
  DefaultProfileDir = '~/.newsfetcher'
  SubscriptionsDirName = 'subscriptions'
  StylesheetFile = Path.new(__FILE__).dirname / '../message/stylesheet.css'

  def self.get(uri, headers: nil)
    redirects = 0
    loop do
      result = HashStruct.new(location: uri)
      response = silence_warnings do
        connection = Faraday.new(
          url: uri,
          headers: headers || {},
          request: { timeout: DownloadTimeout },
          ssl: { verify: false })
        begin
          connection.get
        rescue Faraday::ConnectionFailed, Zlib::BufError, StandardError => e
          return result.merge(type: :error, reason: e)
        end
      end
      result_type = http_status_result_type(response.status)
      if result_type == :redirection
        redirects += 1
        if redirects > DownloadFollowRedirectLimit
          return result.merge(type: :error, reason: "Too many redirects")
        end
        uri = uri.join(Addressable::URI.parse(response.headers[:location]))
        next
      end
      return result.merge(
        type: result_type,
        status: response.status,
        headers: response.headers,
        content: response.body.force_encoding(Encoding::UTF_8))
    end
  end

  def self.http_status_result_type(code)
    case code
    when 100...200
      :informational
    when 200...300
      :successful
    when 304
      :not_modified
    when 300...400
      :redirection
    when 400...500
      :client_error
    when 500...600
      :server_error
    else
      :unknown_status
    end
  end

end

module Kernel

  def silence_warnings(&block)
    warn_level = $VERBOSE
    $VERBOSE = nil
    result = block.call
    $VERBOSE = warn_level
    result
  end

end