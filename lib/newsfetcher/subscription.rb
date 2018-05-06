module NewsFetcher

  class Subscription

    attr_accessor :title
    attr_accessor :link
    attr_accessor :profile
    attr_accessor :dir

    def self.load(profile:, dir:)
      info_file = dir / InfoFileName
      raise Error, "Subscription info file does not exist: #{info_file}" unless info_file.exist?
      info = YAML.load(info_file.read)
      raise Error, "Bad info file: #{info_file}" unless info && !info.empty?
      new(
        info.merge(
          profile: profile,
          dir: dir,
        )
      )
    end

    def initialize(params={})
      params.each { |k, v| send("#{k}=", v) }
    end

    def dir=(dir)
      @dir = Path.new(dir)
    end

    def relative_dir
      @dir.relative_to(@profile.subscriptions_dir)
    end

    def id
      relative_dir.to_s
    end

    def info_file
      @dir / InfoFileName
    end

    def data_file
      @dir / DataFileName
    end

    def history_file
      @dir / HistoryFileName
    end

    def last_modified
      data_file.exist? ? data_file.mtime : nil
    end

    def to_yaml
      {
        'title' => @title,
        'link' => @link.to_s,
      }.to_yaml(line_width: -1)
    end

    def exist?
      @dir.exist?
    end

    def save
      @dir.mkpath unless exist?
      info_file.write(to_yaml)
    end

    def dormant_time
      history = SDBM.open(history_file)
      if (latest = history.values.map { |v| Time.parse(v) }.sort.last)
        Time.now - latest
      else
        nil
      end
    end

    DaySeconds = 24 * 60 * 60

    def dormant_days
      (t = dormant_time) ? (t.to_f / DaySeconds) : t
    end

    def update
      load_feed
    end

    def process(ignore_history: false, limit: nil)
      SDBM.open(history_file) do |history|
        count = 0
        feed = parse_feed
        feed.entries.each do |entry|
          entry_id = entry.entry_id || entry.url or raise Error, "#{id}: Can't determine entry ID"
          entry_id = entry_id.to_s
          if ignore_history || !history[entry_id]
            item = {
              date: entry.published || Time.now,
              style: @profile.style,
              subscription_title: @title || feed.title || 'untitled',
              subscription_description: feed.respond_to?(:description) ? feed.description : nil,
              title: (t = entry.title.to_s.strip).empty? ? 'untitled' : t,
              url: entry.url,
              author: entry.respond_to?(:author) ? entry.author : nil,
              image: entry.respond_to?(:image) ? entry.image : nil,
              content: parse_content(entry.content || entry.summary).to_html,
            }
            @profile.send_item(item, self)
            history[entry_id] = item[:date].to_s
            count += 1
            break if limit && count >= limit
          end
        end
      end
    end

    def load_feed
      headers = {}
      headers[:if_modified_since] = last_modified.rfc2822 if last_modified
      begin
        connection = Faraday.new(
          url: @link,
          headers: headers,
          request: { timeout: DownloadTimeout },
          ssl: { verify: false },
        ) do |conn|
          conn.use(FaradayMiddleware::FollowRedirects, limit: DownloadFollowRedirectLimit)
          conn.adapter(*Faraday.default_adapter)
        end
        response = connection.get
        if response.status == 304
          # ;;warn "#{id}: feed not modified: #{@link}"
          return
        elsif response.success?
          # ;;warn "#{id}: loaded feed: #{@link}"
          last_modified = Time.parse(response.headers[:last_modified] || response.headers[:date])
          data_file.open('w') { |io| io.write(response.body) }
          data_file.utime(last_modified, last_modified)
        else
          raise Error, "Failed to get feed: #{response.status}"
        end
      rescue Faraday::Error, Zlib::BufError => e
        raise Error, "Failed to download resource from #{@link}: #{e}"
      end
    end

    def parse_feed
      raise Error, "No feed data file" unless data_file.exist?
      data = data_file.read
      begin
        Feedjira::Feed.parse(data)
      rescue => e
        raise Error, "Can't parse feed from #{data_file}: #{e}"
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
      save
    end

  end

end