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

  ResultFileName = 'result.json'
  HistoryFileName = 'history'
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
require 'newsfetcher/history'
require 'newsfetcher/item'
require 'newsfetcher/profile'
require 'newsfetcher/result'
require 'newsfetcher/subscription'

require 'newsfetcher/command'
Path.new(__FILE__).dirname.glob('newsfetcher/commands/*.rb').each { |p| require p }

module NewsFetcher

  def self.get(uri, headers: nil)
    redirects = 0
    loop do
      response = silence_warnings do
        connection = Faraday.new(
          url: uri,
          headers: headers || {},
          request: { timeout: DownloadTimeout },
          ssl: { verify: false })
        begin
          connection.get
        rescue Faraday::ConnectionFailed, Zlib::BufError, StandardError => e
          return Result.new(type: :network_error, reason: "#{e.message} (#{e.class})")
        end
      end
      case (result_type = http_status_result_type(response.status))
      when :moved
        return Result.new(type: result_type, reason: "Permanently moved to #{response.headers[:location]}")
      when :redirection
        redirects += 1
        if redirects > DownloadFollowRedirectLimit
          return Result.new(type: :redirect_error, reason: 'Too many redirects')
        end
        uri = uri.join(Addressable::URI.parse(response.headers[:location]))
      else
        return Result.new(
          type: result_type,
          status: response.status,
          reason: response.reason_phrase,
          headers: response.headers,
          content: response.body.force_encoding(Encoding::UTF_8))
      end
    end
  end

  def self.http_status_result_type(code)
    case code
    when 100...200
      :informational
    when 200...300
      :successful
    when 302
      :moved
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