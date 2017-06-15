module Feeder

  class Subscription

    attr_accessor :id
    attr_accessor :title
    attr_accessor :feed_link
    attr_accessor :path

    def self.list
      each_subscription { |s| p(s) }
    end

    def self.update
      each_subscription { |s| s.update }
    end

    def self.process
      feeds = each_subscription.map { |s| s.process }
      Feeder.save_json(feeds, Feeder.compilation_file)
    end

    def self.each_subscription(plist_file=nil, &block)
      plist_file ||= Feeder.subscriptions_file
      return to_enum(__method__) unless block_given?
      IO.popen(['plutil', '-convert', 'xml1', '-o', '-', plist_file.to_s], 'r') do |io|
        plist = Nokogiri::PList(io)
        recurse_plist(plist) do |subscription_plist, path|
          yield new(
            id: subscription_plist['id'],
            title: subscription_plist['name'],
            feed_link: subscription_plist['rss'],
            path: path)
        end
      end
    end

    ###

    def initialize(params={})
      params.each { |k, v| send("#{k}=", v) }
    end

    def feed_dir
      @feed_dir ||= Feeder.data_dir / @id     #/
    end

    def feed_xml_file
      @feed_xml_file ||= feed_dir / FeedXMLFilename
    end

    def errors_file
      @errors_file ||= feed_dir / ErrorsFilename
    end

    def update
      puts "downloading #{@feed_link} to #{feed_xml_file}"
      feed_dir.mkpath unless feed_dir.exist?
      errors_file.unlink if errors_file.exist?
      pid = Process.spawn(
        'download-if-modified',
        @feed_link.to_s,
        feed_xml_file.to_s,
        err: errors_file.to_s)
      pid, status = Process.wait2(pid)
      if status.success?
        errors_file.unlink
      else
        ;;pp(status: status, error: errors_file.read)
      end
    end

    def process
      return unless feed_xml_file.exist?
      begin
        jira_feed = Feedjira::Feed.parse(feed_xml_file.read)
      rescue Feedjira::NoParserAvailable => e
        warn "Can't parse feed file #{feed_xml_file}: #{e}"
        return
      end
      jira_feed.sanitize_entries!
      entries = jira_feed.entries.map do |jira_entry|
        Feeder.object_to_hash(jira_entry, EntryTranslationMap).merge('type' => 'entry')
      end
      Feeder.object_to_hash(jira_feed, FeedTranslationMap).merge('type' => 'feed', 'entries' => entries)
    end

    private

    def self.recurse_plist(items, path=[], &block)
      items.each do |item|
        if item['isContainer']
          recurse_plist(item['childrenArray'], path + [item['name']], &block)
        else
          yield(item, path)
        end
      end
    end
  end

end