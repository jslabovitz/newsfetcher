module NewsFetcher

  module Commands

    class Discover < Command

      def run(args)
        super
        args.map { |a| Addressable::URI.parse(a) }.each do |uri|
          Fetcher.find_feeds(uri).each do |feed|
            feed.each do |key, value|
              puts "%10s: %s" % [key, value]
            end
            puts
          end
        end
      end

    end

  end

end