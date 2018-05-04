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

    def last_modified
      data_file.exist? ? data_file.mtime : nil
    end

    def mail_address(title)
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
      SDBM.open(history_file) do |history|
        count = 0
        jira_feed = parse_feed
        jira_feed.entries.each do |entry|
          entry_id = entry.entry_id || entry.url or raise Error, "#{@path}: Can't determine entry ID"
          entry_id = entry_id.to_s
          if ignore_history || !history[entry_id]
            item = {
              date: entry.published || Time.now,
              style: @profile.style,
              feed_title: @title || jira_feed.title || 'untitled',
              feed_description: jira_feed.respond_to?(:description) ? jira_feed.description : nil,
              title: (t = entry.title.to_s.strip).empty? ? 'untitled' : t,
              url: entry.url,
              author: entry.respond_to?(:author) ? entry.author : nil,
              image: entry.respond_to?(:image) ? entry.image : nil,
              content: parse_content(entry.content || entry.summary).to_html,
            }
            send_item(item)
            history[entry_id] = item[:date].to_s
            count += 1
            break if limit && count >= limit
          end
        end
      end
    end

    def send_item(item)
      ;;warn "#{@path}: #{item[:title].inspect} => #{maildir.path}"
      mail = Mail.new.tap do |m|
        m.date =         item[:date],
        m.from = m.to =  mail_address(item[:title])
        m.subject =      item[:title]
        m.content_type = 'text/html; charset=UTF-8'
        m.body         = ERB.new(@profile.message_template).result_with_hash(item)
      end
      maildir.add(mail)
    end

    def load_feed
      headers = {}
      headers[:if_modified_since] = last_modified.rfc2822 if last_modified
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
          ;;warn "#{@path}: feed not modified: #{@feed_link}"
          return
        elsif response.success?
          ;;raise Error, 'empty response' if response.body.to_s.empty?
          ;;warn "#{@path}: loaded feed: #{@feed_link}"
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
        Feedjira::Feed.parse(data)
      rescue => e
        raise Error, "Can't parse feed: #{e}"
      end
    end

    def parse_content(content)
      html = Nokogiri::HTML::DocumentFragment.parse(content)
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