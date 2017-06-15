require 'json'
require 'date'
require 'path'
require 'uri'
require 'pp'

require 'feedjira'
require 'hashstruct'
require 'nokogiri'
require 'nokogiri-plist'

require 'feeder/version'
require 'feeder/utils'

require 'feeder/extensions/date_time'
require 'feeder/commands'
require 'feeder/profile'
require 'feeder/subscription'

module Feeder

  FeedXMLFilename = 'feed.xml'
  ErrorsFilename = 'errors'
  CompilationFilename = 'compilation.json'
  EntriesDirName = 'entries'
  DefaultDataDir = '~/Projects/vmsg/feeds'
  DefaultSubscriptionsFile = '~/Library/Application Support/NetNewsWire/Subscriptions.plist'

  FeedTranslationMap = [
    'title',
    'description',
    { 'url' => 'home_link' },
    { 'feed_url' => 'feed_link' },
    { 'last_modified' => 'published' },
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

  def self.data_dir
    @data_dir ||= Path.new(DefaultDataDir).expand_path
  end

  def self.subscriptions_file
    @subscriptions_file ||= Path.new(DefaultSubscriptionsFile).expand_path
  end

  def self.compilation_file
    data_dir / CompilationFilename
  end

end