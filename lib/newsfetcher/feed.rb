module NewsFetcher

  class Feed

    attr_accessor :title
    attr_accessor :feed_link
    attr_accessor :last_modified
    attr_accessor :profile
    attr_accessor :path

    def self.load(profile:, path:)
      info_file = profile.feeds_dir / path / FeedInfoFileName
      raise Error, "Feed info file does not exist: #{info_file}" unless info_file.exist?
      info = YAML.load(info_file.read)
      raise Error, "Bad info file: #{info_file}" unless info && !info.empty?
      new(
        info.merge(
          path: path,
          profile: profile,
        )
      )
    end

    def initialize(params={})
      params.each { |k, v| send("#{k}=", v) }
    end

    def dir
      @profile.feeds_dir / @path
    end

    def info_file
      dir / FeedInfoFileName
    end

    def data_file
      dir / FeedDataFileName
    end

    def history_file
      dir / FeedHistoryFileName
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

    def maildir
      @maildir ||= @profile.maildir_for_feed(self)
    end

    def open_history
      @history ||= SDBM.open(history_file)
    end

    def to_yaml
      {
        'title' => @title,
        'feed_link' => @feed_link.to_s,
        'last_modified' => @last_modified.dup,    # to avoid YAML references
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
        open_history
        count = 0
        @feed.entries.each do |entry|
          entry_id = entry.entry_id || entry.url or raise Error, "#{@path}: Can't determine entry ID"
          entry_id = entry_id.to_s
          if ignore_history || !@history[entry_id]
            send_entry(entry)
            @history[entry_id] = (entry.published || Time.now).to_s
            count += 1
            break if limit && count >= limit
          end
        end
        save  ##FIXME: remove once last_modified is removed from info file
      end
    end

    def send_entry(entry)
      entry_title = entry.title.to_s.strip
      entry_title = 'untitled' if entry_title.empty?
      ;;puts "#{@path}: #{entry_title.inspect} => #{maildir.path}"
      mail = Mail.new.tap do |m|
        m.date =         entry.published
        m.from =         mail_address
        m.to =           mail_address
        m.subject =      entry_title
        m.content_type = 'text/html; charset=UTF-8'
        m.body =         make_content(entry)
      end
      maildir.add(mail)
    end

    def load_feed
      # ;;warn "#{@path}: loading feed from #{@feed_link}"
      response = NewsFetcher.get(@feed_link, if_modified_since: @last_modified)
      return false if response.status == 304 || response.body.nil? || response.body == ''
      raise Error, "Failed to get feed: #{response.status}" unless response.success?
      data_file.open('w') { |io| io.write(response.body) }
      begin
        @feed = Feedjira::Feed.parse(response.body)
      rescue Feedjira::NoParserAvailable => e
        raise Error, "Can't parse feed: #{e}"
      end
      @last_modified = @feed.last_modified
      data_file.utime(@feed.last_modified, @feed.last_modified)
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