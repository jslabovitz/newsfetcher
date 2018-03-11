module Feeder

  class Subscription

    attr_accessor :title
    attr_accessor :feed_link
    attr_accessor :history
    attr_accessor :dir
    attr_accessor :profile

    def self.load(dir:, profile:)
      dir = Path.new(dir)
      info = YAML.load((dir / InfoFile).read)
      new(info.merge(dir: dir, profile: profile))
    end

    def initialize(params={})
      @history = {}
      params.each { |k, v| send("#{k}=", v) }
    end

    def id
      @dir.relative_to(@profile.dir).to_s
    end

    def feed_file
      @dir / FeedFile
    end

    def info_file
      @dir / InfoFile
    end

    def to_yaml
      {
        'title' => @title,
        'feed_link' => @feed_link.to_s,
        'history' => @history,
      }.to_yaml
    end

    def save
      @dir.mkpath unless @dir.exist?
      info_file.write(to_yaml)
    end

    def summary
      "#{@dir.relative_to(Feeder.subscriptions_dir)}: #{@title.inspect} <#{@feed_link}>"
    end

    UserAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/604.1.25 (KHTML, like Gecko) Version/11.0 Safari/604.1.25'

    def update(options)
      puts "updating #{id} (#{@feed_link})"
      command = [
        'curl',
        @feed_link,
        # '--verbose',
        # '--silent',
        '--progress-bar',
        '--fail',
        '--location',
        '--user-agent', UserAgent,
        feed_file.exist? ? ['--time-cond', feed_file] : [],
        '--output', feed_file,
      ].flatten.compact.map(&:to_s)
      system(*command)
      raise Error, "Couldn't download feed: #{$?}" unless $?.success?
    end

    def process(force: false)
      puts "processing #{id} (#{@feed_link})"
      load_feed
      @feed.entries.each do |entry|
        entry_id = entry.entry_id || entry.url or raise Error, "#{id}: Can't determine entry ID"
        if force || !@history[entry_id]
          process_msg(entry)
          @history[entry_id] = entry.published || DateTime.now
        end
      end
      save
    end

    def load_feed
      raise Error, "No feed file" unless feed_file.exist?
      begin
        @feed = Feedjira::Feed.parse(feed_file.read)
      rescue Feedjira::NoParserAvailable => e
        raise Error, "Can't parse feed: #{e}"
      end
    end

    def folder_paths
      @dir.relative_to(@profile.dir).each_filename.to_a[0..-2]
    end

    def process_msg(entry)
      subaddress = ['News', *folder_paths].join('.')
      address = "jlabovitz+#{subaddress}@fastmail.fm"
      display_name = @feed.title
      msg = %Q{
Date: #{entry.published.rfc2822}
From: #{display_name} <#{address}>
To: #{display_name} <#{address}>
Subject: #{entry.title}
Content-Type: text/html; charset=UTF-8

#{make_content(entry)}
}.strip
      maildir = Maildir.new([MailDir, 'News', *folder_paths].join('/'))
      maildir.add(msg)
    end

    def make_content(entry)
      doc = Nokogiri::HTML::Document.new
      doc.encoding = 'UTF-8'
      doc.internal_subset.remove
      doc.create_internal_subset('html', nil, nil)
      Nokogiri::HTML::Builder.with(doc) do |html|
        html.html do
          html.body do
            html.h2 do
              html.a(href: entry.url) { html << entry.title }
            end
            if entry.author
              html.h4("by #{entry.author.sub(/^by\s+/i, '')}")
            end
            if entry.image
              html.p { html.img(src: entry.image) }
            end
            content_html = Nokogiri::HTML::DocumentFragment.parse(entry.content || entry.summary)
            #FIXME: modify content as needed
            html << content_html.to_html
            html.hr
            html.h3 do
              html.a(href: @feed.url) { html << @feed.title }
            end
            if @feed.description
              html.h3 { html << @feed.description }
            end
          end
        end
      end
      doc.to_s
    end

    ListFeedKeys = %i{title description url}
    ListFeedKeysMax = ListFeedKeys.map(&:to_s).map(&:length).max

    ListEntryKeys = %i{title image published updated last_modified author url}
    ListEntryKeysMax = ListEntryKeys.map(&:to_s).map(&:length).max

    def list(entries: false)
      load_feed
      ListFeedKeys.each do |key|
        if @feed.respond_to?(key) && (value = @feed.send(key))
          puts "%*s: %s" % [ListFeedKeysMax, key, value]
        end
      end
      if entries
        puts "%*s:" % [ListFeedKeysMax, 'entries']
        @feed.entries.each do |entry|
          ListEntryKeys.each do |key|
            if entry.respond_to?(key) && (value = entry.send(key))
              puts "\t%*s: %s" % [ListEntryKeysMax, key, value]
            end
          end
          puts
        end
      end
      puts
    end

  end

end