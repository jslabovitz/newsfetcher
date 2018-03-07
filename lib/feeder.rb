require 'date'
require 'json'
require 'path'
require 'uri'
require 'yaml'

require 'feedjira'
require 'hashstruct'
require 'maildir'
require 'nokogiri'
require 'nokogiri-plist'
require 'simple_option_parser'

require 'feeder/version'
require 'feeder/utils'

require 'feeder/extensions/date_time'
require 'feeder/commands'
require 'feeder/profile'
require 'feeder/subscription'

module Feeder

  FeedXMLFile = 'feed.xml'
  FeedInfoFile = 'info.json'
  FeedHistoryFile = 'history.json'
  DataDir = '~/.feeds'
  SubscriptionsFile = '~/Library/Application Support/NetNewsWire/Subscriptions.plist'

  FeedTranslationMap = [
    'title',
    'description',
    { 'url' => 'home_link' },
    { 'feed_url' => 'feed_link' },
    { 'last_modified' => 'published' },
  ]
  FeedWhitewashKeys = [
    'title',
    'description',
  ]
  EntryTranslationMap = [
    'title',
    'author',
    'id',
    { 'url' => 'link' },
    'image',
    'modified',
    'published',
    'summary',
    'content',
  ]
  EntryWhitewashKeys = [
    'title',
    'author',
    'summary',
    'content',
  ]

  class Error < Exception; end

  def self.data_dir
    @data_dir ||= Path.new(DataDir).expand_path
  end

  def self.subscriptions_file
    @subscriptions_file ||= Path.new(SubscriptionsFile).expand_path
  end

end