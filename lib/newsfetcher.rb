require 'date'
require 'logger'
require 'uri'
require 'yaml'

require 'faraday'
require 'feedjira'
require 'loofah'
require 'mail'
require 'nokogiri'
require 'path'
require 'simple-command'

require 'newsfetcher/error'
require 'newsfetcher/item'
require 'newsfetcher/profile'
require 'newsfetcher/subscription'

module NewsFetcher

  InfoFileName = 'info.yaml'
  FeedFileName = 'feed'
  HistoryFileName = 'history'
  DownloadTimeout = 30
  DownloadFollowRedirectLimit = 5
  DefaultMaxThreads = 100
  DefaultDormantTime = 30 * 24 * 60 * 60    # one month
  DefaultProfileDir = '~/.newsfetcher'
  SubscriptionsDirName = 'subscriptions'
  StylesheetFile = Path.new(__FILE__).dirname / '../message/stylesheet.css'

  def self.save_yaml(path, obj)
    hash = Hash[
      obj.reject { |k, v| v.nil? }.map { |k, v| [k.to_s, v.to_s] }
    ]
    path.dirname.mkpath unless path.dirname.exist?
    path.write(hash.to_yaml(line_width: -1))
  end

  def self.load_yaml(path)
    path = path.expand_path
    raise Error, "File does not exist: #{path}" unless path.exist?
    obj = YAML.load(path.read)
    raise Error, "Bad file: #{path}" unless obj && !obj.empty?
    obj
  end

end