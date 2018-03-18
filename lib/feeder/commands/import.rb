module Feeder

  module Commands

    class Import < Command

      register_command 'import'

      def run(args)
        plist_file = args.shift or raise Error, "Must specify plist file"
        io = IO.popen(['plutil', '-convert', 'xml1', '-o', '-', plist_file], 'r')
        plist = Nokogiri::PList(io)
        recurse_plist(plist) do |item, path|
          key = Feeder.uri_to_key(item['rss'])
          puts "importing %-60s => %s" % [item['rss'], key]
          feed = Feed.new(
            id: [path, key].join('/'),
            feed_link: item['rss'],
            profile: self)
          raise "Feed exists: #{feed.info_file}" if feed.info_file.exist?
          feed.save
          ;;warn "saved new feed to #{feed.info_file}"
        end
      end

      def recurse_plist(items, path=[], &block)
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

end