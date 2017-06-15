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
require 'feeder/extensions/date_time'
require 'feeder/commands'
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

  def self.save_json(object, file)
    file.dirname.mkpath unless file.dirname.exist?
    file.open('w') { |io| io.write(JSON.pretty_generate(object)) }
  end

  def self.load_json(file)
    JSON.parse(file.read)
  end

  def self.object_to_hash(from_obj, translation_map)
    hash = {}
    translation_map.each do |item|
      from_method, to_method = case item
      when Hash
        [item.keys.first, item.values.first]
      when String, Symbol
        [item, item]
      else
        raise "Bad element in translation map: #{item.inspect}"
      end
      from_method = from_method.to_sym
      to_method = to_method.to_s
      if from_obj.respond_to?(from_method) && (value = from_obj.send(from_method))
        # ;;pp(value: value)
        if value.kind_of?(String)
          value.strip!
          value = nil if value.empty?
        end
        hash[to_method] = value if value
      end
    end
    hash
  end
end