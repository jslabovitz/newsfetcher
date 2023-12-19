module NewsFetcher

  module Commands

    class Discover < Command

      def run(args)
        super
        args.map { |a| Addressable::URI.parse(a) }.each do |uri|
          fetcher = Fetcher.get(uri)
          if fetcher.success?
            fetcher.find_feeds.each do |feed|
              feed.each do |key, value|
                puts "%10s: %s" % [key, value]
              end
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