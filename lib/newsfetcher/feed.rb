module NewsFetcher

  class Feed

    attr_accessor :title
    attr_accessor :feed_link
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

    def last_modified
      data_file.exist? ? data_file.mtime : nil
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
      if last_modified
        Time.now - last_modified
      else
        nil
      end
    end

    DaySeconds = 24 * 60 * 60

    def dormant_days
      (t = dormant_time.to_f) ? (t / DaySeconds) : t
    end

    def update
      load_feed
    end

    def process(ignore_history: false, limit: nil)
      parse_feed
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
      ;;warn "#{@path}: loading feed from #{@feed_link}"
      headers = {}
      headers[:if_modified_since] = data_file.mtime.rfc2822 if data_file.exist?
      begin
        connection = Faraday.new(
          url: @feed_link,
          headers: headers,
          request: { timeout: FeedDownloadTimeout },
          ssl: { verify: false },
        ) do |conn|
          conn.use(FaradayMiddleware::FollowRedirects, limit: FeedDownloadFollowRedirectLimit)
          conn.adapter(*Faraday.default_adapter)
        end
        response = connection.get
        if response.status == 304
          return
        elsif response.success?
          raise Error, 'empty response' if response.body.to_s.empty?
          last_modified = Time.parse(response.headers[:last_modified] || response.headers[:date])
          data_file.open('w') { |io| io.write(response.body) }
          data_file.utime(last_modified, last_modified)
        else
          raise Error, "Failed to get feed: #{response.status}"
        end
      rescue Faraday::Error, Zlib::BufError => e
        raise Error, "Failed to download resource from #{@feed_link}: #{e}"
      end
    end

    def parse_feed
      raise Error, "No feed data file" unless data_file.exist?
      data = data_file.read
      begin
        @feed = Feedjira::Feed.parse(data)
      rescue Feedjira::NoParserAvailable => e
        raise Error, "Can't parse feed: #{e}"
      end
    end

    def make_content(entry)
      ERB.new(@profile.message_template).result_with_hash(
        style: @profile.style,
        feed_title: @feed.title,
        feed_description: @feed.respond_to?(:description) ? @feed.description : nil,
        title: entry.title,
        url: entry.url,
        author: entry.respond_to?(:author) ? entry.author : nil,
        image: entry.respond_to?(:image) ? entry.image : nil,
        content: parse_content(entry).to_html,
      )
    end

    def parse_content(entry)
      html = Nokogiri::HTML::DocumentFragment.parse(entry.content || entry.summary)
      html.xpath('div[@class="feedflare"]').each(&:remove)
      html.xpath('img[@height="1" and @width="1"]').each(&:remove)
      #FIXME: doesn't work
      # html.search('iframe').each { |e| e.delete('width'); e.delete('height') }
      html
    end

    def fix
    end

  end

end