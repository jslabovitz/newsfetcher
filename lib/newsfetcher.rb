require 'date'
require 'sdbm'
require 'uri'
require 'yaml'

require 'faraday'
require 'feedjira'
require 'loofah'
require 'mail'
require 'nokogiri'
require 'path'
require 'public_suffix'
require 'simple-command'

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

  Feedjira.configure do |config|
    config.strip_whitespace = true
  end

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
        raise Error, "Unexpected status: #{response.status}"
      end
    rescue Faraday::Error, Zlib::BufError, Error => e
      raise Error, "Failed to get #{uri}: #{e}"
    end
  end

  def self.load_yaml(path)
    path = path.expand_path
    raise Error, "File does not exist: #{path}" unless path.exist?
    info = YAML.load(path.read)
    raise Error, "Bad file: #{info_file}" unless info && !info.empty?
    info
  end

  def self.parse_content(content)
    remove_feedflare = Loofah::Scrubber.new do |node|
      node.remove if node.name == 'div' && node['class'] == 'feedflare'
    end
    remove_beacon = Loofah::Scrubber.new do |node|
      node.remove if node.name == 'img' && node['height'] == '1' && node['width'] == '1'
    end
    remove_font = Loofah::Scrubber.new do |node|
      node.replace(node.children) if %w{font big small}.include?(node.name)
    end
    remove_form = Loofah::Scrubber.new do |node|
      node.replace(node.children) if node.name == 'form'
    end
    remove_styling = Loofah::Scrubber.new do |node|
      node.remove_attribute('style') if node['style']
      node.remove_attribute('class') if node['class']
      node.remove_attribute('id') if node['id']
    end
    Loofah.fragment(content).
      scrub!(:prune).
      scrub!(remove_beacon).
      scrub!(remove_feedflare).
      scrub!(remove_font).
      scrub!(remove_form).
      scrub!(remove_styling)
  end

  def self.html_document(&block)
    doc = Nokogiri::HTML::Document.new
    doc.encoding = 'UTF-8'
    Nokogiri::HTML::Builder.with(doc) do |html|
      html.html do
        yield(html) if block_given?
      end
    end
    doc
  end

  def self.html_fragment(&block)
    fragment = Nokogiri::HTML::DocumentFragment.parse('')
    Nokogiri::HTML::Builder.with(fragment) do |html|
      yield(html) if block_given?
    end
    fragment
  end

  def self.replace_fields(str, fields)
    str.to_s.gsub(/%(\w)/) do
      fields[$1] or raise "Unknown tag: #{$1.inspect}"
    end
  end

end