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
      @feed_xml_file ||= feed_dir / FeedXMLFilename
    end

    def new_feed_xml_file
      @new_feed_xml_file ||= feed_dir / NewFeedXMLFilename
    end

    def feed_info_file
      @feed_info_file ||= feed_dir / FeedInfoFilename
    end

    def update
      puts; puts "---"
      puts "#{@feed_link}"
      feed_dir.mkpath unless feed_dir.exist?
      errors_file.unlink if errors_file.exist?
      args = [
        'curl',
        @feed_link.to_s,
        '--verbose',
        '--silent',
        '--location',
        '--time-cond', feed_xml_file.to_s,
        '--output', new_feed_xml_file.to_s,
      ]
      pid = Process.spawn(*args.map(&:to_s))
      pid, status = Process.wait2(pid)
      ;;pp status unless status.success?
    end

    EntryWhitewashedKeys = %w{title author summary content}

    def process
      old_feed, new_feed = [feed_xml_file, new_feed_xml_file].map { |f| read_feed(f) }
      return unless new_feed

      new_entry_ids = new_feed.entries.map(&:entry_id)
      old_entry_ids = old_feed ? old_feed.entries.map(&:entry_id) : []
      ids = (new_entry_ids - old_entry_ids)

      feed = Feeder.object_to_hash(new_feed, FeedTranslationMap).merge('type' => 'feed')
      Feeder.save_json(feed, feed_info_file)

      unless ids.empty?
        ;;puts; puts "* #{feed.to_json}"
        new_feed.entries.select { |e| ids.include?(e.entry_id) }.each do |jira_entry|
          entry = Feeder.object_to_hash(jira_entry, EntryTranslationMap).merge('type' => 'entry')
          EntryWhitewashedKeys.each do |key|
            entry[key] = Loofah.scrub_fragment(entry[key], :whitewash).to_s if entry[key]
          end
          ;;puts "** #{entry.to_json}"
        end
      end

      # feed_xml_file.unlink
      # new_feed_xml_file.rename(feed_xml_file)
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