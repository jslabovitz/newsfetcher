module NewsFetcher

  class Feed

    attr_accessor :title
    attr_accessor :feed_link
    attr_accessor :last_modified
    attr_accessor :history
    attr_accessor :profile
    attr_accessor :path

    def self.load(profile:, path:)
      info_file = profile.feeds_dir / path / FeedInfoFileName
      raise Error, "Feed info file does not exist: #{info_file}" unless info_file.exist?
      info = YAML.load(info_file.read)
      new(
        info.merge(
          path: path,
          profile: profile,
        )
      )
    end

    def initialize(params={})
      @history = {}
      params.each { |k, v| send("#{k}=", v) }
    end

    def dir
      @profile.feeds_dir / @path
    end

    def info_file
      dir / FeedInfoFileName
    end

    def xml_file
      dir / FeedXMLFileName
    end

    def title
      @title || (@feed ? @feed.title : nil)
    end

    def mail_address
      Mail::Address.new.tap do |a|
        a.display_name = title
        a.address = "%s+%s@%s" % [
          @profile.email.local,
          [@profile.folder, *@path.each_filename.to_a].join('.'),
          @profile.email.domain,
        ]
      end
    end

    def to_yaml
      {
        'title' => @title,
        'feed_link' => @feed_link.to_s,
        'last_modified' => @last_modified.dup,    # to avoid YAML references
        'history' => @history,
      }.to_yaml(line_width: -1)
    end

    def exist?
      dir.exist?
    end

    def save
      dir.mkpath unless exist?
      info_file.write(to_yaml)
    end

    def dormant_time
      if @last_modified
        Time.now - @last_modified
      else
        nil
      end
    end

    DaySeconds = (24*60*60).to_f

    def dormant_days
      (t = dormant_time) ? (t / DaySeconds) : t
    end

    def update(ignore_history: false, limit: nil)
      if load_feed
        maildir = @profile.maildir_for_feed(self)
        count = 0
        @feed.entries.each do |entry|
          entry_id = entry.entry_id || entry.url or raise Error, "#{@path}: Can't determine entry ID"
          if ignore_history || !@history[entry_id]
            puts
            puts "#{@path}:"
            puts "\t%10s: %s" % ['entry ID', entry_id]
            puts "\t%10s: %s" % ['maildir', maildir.path]
            puts "\t%10s: %s" % ['email', mail_address]
            content = make_content(entry)
            mail = Mail.new.tap do |m|
              m.date =         entry.published
              m.from =         mail_address
              m.to =           mail_address
              m.subject =      entry.title.strip
              m.content_type = 'text/html; charset=UTF-8'
              m.body =         content
            end
            maildir.add(mail)
            @history[entry_id] = entry.published || Time.now
            count += 1
            break if limit && count >= limit
          end
        end
        save
      end
    end

    def load_feed
      # ;;warn "#{@path}: loading feed from #{@feed_link}"
      @feed_data = nil
      response = NewsFetcher.get(@feed_link, if_modified_since: @last_modified)
      return false if response.status == 304 || response.body.nil? || response.body == ''
      raise Error, "Failed to get feed: #{response.status}" unless response.success?
      begin
        @feed = Feedjira::Feed.parse(response.body)
      rescue Feedjira::NoParserAvailable => e
        raise Error, "Can't parse feed: #{e}"
      end
      @last_modified = @feed.last_modified
      true
    end

    def make_content(entry)
      doc = Nokogiri::HTML::Document.new
      doc.encoding = 'UTF-8'
      doc.internal_subset.remove
      doc.create_internal_subset('html', nil, nil)
      Nokogiri::HTML::Builder.with(doc) do |html|
        html.html do
          html.head do
            html.style(@profile.style)
          end
          html.body do
            html.div(class: 'bar') do
              html << title
            end
            html.h1 do
              html.a(href: entry.url) { html << entry.title }
            end
            if entry.respond_to?(:author) && entry.author
              html.div(class: 'author') { html << entry.author }
            end
            if entry.respond_to?(:image) && entry.image
              html.div(class: 'image') { html.img(src: entry.image) }
            end
            html.div(class: 'content') { html << parse_content(entry).to_html }
            if @feed.respond_to?(:description) && @feed.description
              html.div(class: 'bar') do
                html << @feed.description
              end
            end
          end
        end
      end
      doc.to_s
    end

    def parse_content(entry)
      html = Nokogiri::HTML::DocumentFragment.parse(entry.content || entry.summary)
      html.xpath('div[@class="feedflare"]').each(&:remove)
      html.xpath('img[@height="1" and @width="1"]').each(&:remove)
      #FIXME: doesn't work
      html.search('iframe').each { |e| e.delete('width'); e.delete('height') }
      html
    end

    def fix
    end

  end

end