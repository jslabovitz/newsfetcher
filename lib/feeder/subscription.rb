module Feeder

  class Subscription

    attr_accessor :id
    attr_accessor :title
    attr_accessor :feed_link
    attr_accessor :path

    def initialize(params={})
      params.each { |k, v| send("#{k}=", v) }
    end

    def feed_dir
      @feed_dir ||= Feeder.data_dir / @id     #/
    end

    def feed_xml_file
      @feed_xml_file ||= feed_dir / FeedXMLFile
    end

    def feed_info_file
      @feed_info_file ||= feed_dir / FeedInfoFile
    end

    def history_file
      @history_file ||= feed_dir / FeedHistoryFile
    end

    UserAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/604.1.25 (KHTML, like Gecko) Version/11.0 Safari/604.1.25'

    def update
      puts "#{@title.inspect} (#{@id}) <#{@feed_link}>"
      feed_dir.mkpath unless feed_dir.exist?
      args = [
        'curl',
        @feed_link,
        # '--verbose',
        # '--silent',
        '--progress-bar',
        '--fail',
        '--location',
        '--user-agent', UserAgent,
        feed_xml_file.exist? ? ['--time-cond', feed_xml_file] : [],
        '--output', feed_xml_file,
      ].flatten.compact.map(&:to_s)
      pid = Process.spawn(*args)
      pid, status = Process.wait2(pid)
      raise "Couldn't download feed: #{status}" unless status.success?
    end

    def process
      raise "Feed file not found" unless feed_xml_file.exist?
      begin
        jira_feed = Feedjira::Feed.parse(feed_xml_file.read)
      rescue Feedjira::NoParserAvailable => e
        raise "Can't parse feed file: #{e}"
      end
      feed = Feeder.object_to_hash(jira_feed, 'feed', FeedTranslationMap, FeedWhitewashKeys)
      Feeder.save_json(feed, feed_info_file)
      history = history_file.exist? ? Feeder.load_json(history_file) : {}
      maildir = Maildir.new(feed_dir)
      maildir.serializer = Maildir::Serializer::JSON.new
      ;;puts
      jira_feed.entries.each do |jira_entry|
        id = jira_entry.entry_id || jira_entry.url
        unless history[id]
          entry = Feeder.object_to_hash(jira_entry, 'entry', EntryTranslationMap, EntryWhitewashKeys)
          unless entry['link'] =~ /^http/
            home_link = URI.parse((feed['home_link'] =~ /^http/) ? feed['home_link'] : @feed_link)
            entry_link = URI.parse(entry['link'])
            entry['link'] = (home + entry_link).to_s
          end
          ;;pp(subscription: @id, entry: entry['title'], link: entry['link'])
          maildir.add(entry)
          history[id] = DateTime.now
        end
      end
      Feeder.save_json(history, history_file)
    end

    def list
      puts @title
      puts @feed_link
      puts (@path + [@id]).join(' / ')
      puts
    end

    private

    def read_feed(xml_file)
      if xml_file.exist?
        begin
          return Feedjira::Feed.parse(xml_file.read)
        rescue Feedjira::NoParserAvailable => e
          warn "Can't parse feed file #{xml_file}: #{e}"
        end
      end
      nil
    end

  end

end