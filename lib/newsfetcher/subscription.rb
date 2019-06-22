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
      params.each { |k, v| send("#{k}=", v) if v }
    end

    def dir=(dir)
      @dir = Path.new(dir)
    end

    def link=(link)
      @link = link.kind_of?(URI) ? link : URI.parse(link)
    end

    def relative_dir
      @dir.relative_to(@profile.subscriptions_dir)
    end

    def id
      relative_dir.to_s
    end

    def base_id
      relative_dir.basename.to_s
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

    def exist?
      @dir.exist?
    end

    def save
      NewsFetcher.save_yaml(info_file,
        title: @title,
        link: @link)
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
        @profile.logger.debug { "#{id}: loaded feed: #{@link}" }
        last_modified = Time.parse(response.headers[:last_modified] || response.headers[:date])
        feed_file.write(response.body)
        feed_file.utime(last_modified, last_modified)
      end
    end

    def process(&block)
      SDBM.open(history_file) do |history|
        feed = parse_feed
        feed_items(feed).each do |item|
          unless history[item.id]
            yield(item)
            history[item.id] = item.date.to_s
          end
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

    def feed_items(feed)
      feed.entries.collect do |entry|
        Item.new(
          feed: feed,
          entry: entry,
          subscription: self,
          profile: @profile)
      end
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

    def show(keys)
      feed = parse_feed
      puts; puts '%s:' % (@title || feed.title)
      feed_items(feed).each do |item|
        item.show(keys)
        puts
      end
    end

    def show_message
      feed = parse_feed
      feed_items(feed).each do |item|
        email = item.make_email
        puts email.body.to_s
      end
    end

  end

end