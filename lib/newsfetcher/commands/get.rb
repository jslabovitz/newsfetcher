module NewsFetcher

  module Commands

    class Get < Command

      def run(args)
        super
        args.each do |uri|
          fetcher = Fetcher.get(uri)
          if fetcher.success?
            feed = fetcher.parse_feed
            puts
            puts "URI: #{uri}"
            puts "Title: #{feed[:title]}"
            puts "Items:"
            feed[:items].each do |item|
              item.print
              puts
            end
          else
            warn "#{uri}: HTTP error #{fetcher.response_status} (#{fetcher.response_reason})"
          end
        end
      end

    end

  end

end