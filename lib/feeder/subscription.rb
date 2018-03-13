module Feeder

  class Subscription

    attr_accessor :id
    attr_accessor :title
    attr_accessor :feed_link
    attr_accessor :last_modified
    attr_accessor :history
    attr_accessor :profile

    def self.load(info_file:, profile:)
      id = info_file.relative_to(profile.feeds_dir).without_extension
      info = YAML.load(info_file.read)
      new(
        info.merge(
          id: id,
          profile: profile)
      )
    end

    def initialize(params={})
      @history = {}
      params.each { |k, v| send("#{k}=", v) }
    end

    def info_file
      Path.new(@profile.feeds_dir, id).add_extension('.yaml')
    end

    def to_yaml
      {
        'title' => @title,
        'feed_link' => @feed_link.to_s,
        'last_modified' => @last_modified,
        'history' => @history,
      }.to_yaml
    end

    def save
      info_file.dirname.mkpath unless info_file.dirname.exist?
      info_file.write(to_yaml)
    end

    def update(ignore_history: false)
      load_feed
      if @feed_data
        maildir = Maildir.new(Path.new(@profile.maildir, id).dirname.to_s)
        begin
          @feed = Feedjira::Feed.parse(@feed_data)
        rescue Feedjira::NoParserAvailable => e
          raise Error, "Can't parse feed: #{e}"
        end
        @last_modified = @feed.last_modified
        @feed.entries.each do |entry|
          entry_id = entry.entry_id || entry.url or raise Error, "#{id}: Can't determine entry ID"
          if ignore_history || !@history[entry_id]
            ;;warn "#{id}: adding entry #{entry_id}"
            maildir.add(
              make_message(
                date: entry.published,
                from: @title || @feed.title,
                to: @title || @feed.title,
                subject: entry.title,
                content: make_content(entry),
              )
            )
            @history[entry_id] = entry.published || DateTime.now
          end
        end
        save
      end
    end

    def load_feed
      # ;;warn "#{id}: loading feed from #{@feed_link}"
      @feed_data = nil
      if @feed_link =~ %r{^file://localhost(/.*)}
        load_local_feed($1)
      else
        load_remote_feed
      end
    end

    def load_local_feed(file)
      file = Path.new(file)
      @feed_data = file.read
      @last_modified = file.mtime
    end

    def load_remote_feed
      response = Feeder.get(@feed_link, if_modified_since: @last_modified)
      return if response.status == 304
      raise Error, "Failed to get feed: #{response.status}" unless response.success?
      @feed_data = response.body
      if (timestamp = response.headers['last-modified'])
        @last_modified = begin
          DateTime.parse(timestamp)
        rescue StandardError => e
          warn "Failed to parse Last-Modified date: #{timestamp.inspect}"
          nil
        end
      end
    end

    def make_message(date:, from:, to:, subject:, content:)
      %Q{
Date: #{date.rfc2822}
From: #{from} <#{@profile.email}>
To: #{to} <#{@profile.email}>
Subject: #{subject}
Content-Type: text/html; charset=UTF-8

#{content}
}.strip
    end

    def make_content(entry)
      doc = Nokogiri::HTML::Document.new
      doc.encoding = 'UTF-8'
      doc.internal_subset.remove
      doc.create_internal_subset('html', nil, nil)
      Nokogiri::HTML::Builder.with(doc) do |html|
        html.html do
          html.head do
            html.style %Q{
              a {
                text-decoration: none;
              }
              img {
                  max-width: 100%;
                  /*max-height: 100%;*/
                  height: auto;
              }
            }.strip
          end
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
              html.a(href: @feed.url) { html << @title || @feed.title }
            end
            if @feed.description
              html.h3 { html << @feed.description }
            end
          end
        end
      end
      doc.to_s
    end

    def fix(options={})
      @last_modified = @last_modified.to_time if @last_modified
      @history = Hash[ @history.map { |k, v| [k, v.to_time] } ]
    end

  end

end