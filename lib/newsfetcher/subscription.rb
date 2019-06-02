module NewsFetcher

  class Subscription

    attr_accessor :title
    attr_accessor :link
    attr_accessor :profile
    attr_accessor :dir
    attr_accessor :history

    def self.load(profile:, dir:)
      history = load_history(dir / HistoryFileName)
      new(
        {
          profile: profile,
          dir: dir,
          history: history,
        }.merge(NewsFetcher.load_yaml(dir / InfoFileName))
      )
    end

    def self.load_history(path)
      history = {}
      SDBM.open(path) do |db|
        history = db.map { |k, v| [k, Time.parse(v)] }.to_h
      end
      history
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

    def feed_file
      @dir / FeedFileName
    end

    def history_file
      @dir / HistoryFileName
    end

    def last_modified
      feed_file.exist? ? feed_file.mtime : nil
    end

    def to_yaml
      {
        'title' => @title,
        'link' => @link.to_s,
      }.reject { |k, v| v.nil? }.to_yaml(line_width: -1)
    end

    def exist?
      @dir.exist?
    end

    def save
      @dir.mkpath unless exist?
      info_file.write(to_yaml)
    end

    def latest_item_timestamp
      @history.values.sort.last
    end

    def status
      last = latest_item_timestamp
      if last
        if (Time.now - last) > DefaultDormantTime
          :dormant
        else
          :active
        end
      else
        :new
      end
    end

    def update_feed
      if (response = NewsFetcher.get(@link, last_modified ? { if_modified_since: last_modified.rfc2822 } : nil))
        # ;;warn "#{id}: loaded feed: #{@link}"
        last_modified = Time.parse(response.headers[:last_modified] || response.headers[:date])
        feed_file.write(response.body)
        feed_file.utime(last_modified, last_modified)
      end
    end

    def process
      SDBM.open(history_file) do |history|
        feed = parse_feed
        feed.entries.each do |entry|
          entry_id = entry.entry_id || entry.url or raise Error, "#{id}: Can't determine entry ID"
          entry_id = entry_id.to_s
          next if history[entry_id]
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
        end
      end
    end

    def parse_feed
      raise Error, "No feed file" unless feed_file.exist?
      feed = feed_file.read
      begin
        Feedjira::Feed.parse(feed)
      rescue => e
        raise Error, "Can't parse feed from #{feed_file}: #{e}"
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

    def reset
      [
        feed_file,
        history_file.add_extension('.dir'),
        history_file.add_extension('.pag'),
      ].each do |file|
        file.unlink if file.exist?
      end
    end

    def remove
      @dir.rmtree
    end

    def fix
    end

  end

end