module NewsFetcher

  module Commands

    class Import < Command

      register_command 'import'

      def run(args)
        plist_file = args.shift or raise Error, "Must specify plist file"
        io = IO.popen(['plutil', '-convert', 'xml1', '-o', '-', plist_file], 'r')
        plist = Nokogiri::PList(io)
        recurse_plist(plist)
      end

      def recurse_plist(items, path=[], &block)
        items.each do |item|
          if item['isContainer']
            recurse_plist(item['childrenArray'], path + [item['name']], &block)
          else
            @profile.subscribe(uri: item['rss'], path: path)
          end
        end
      end

    end

  end

end