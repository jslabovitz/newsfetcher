module NewsFetcher

  module Commands

    class Get < Command

      def run(args)
        super
        args.each do |uri|
          fetcher = Fetcher.new(uri: uri)
          feed = fetcher.parse_feed
          puts
          puts "URI: #{fetcher.uri}"
          puts "Status: #{fetcher.response_status} #{fetcher.response_reason}"
          puts "Title: #{feed[:title]}"
          puts "Items:"
          feed[:items].each do |item|
            item.print
          end
        end
      end

    end

  end

end