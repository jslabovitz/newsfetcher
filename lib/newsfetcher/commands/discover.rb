module NewsFetcher

  module Commands

    class Discover < Command

      def run(args)
        super
        args.each do |uri|
          @profile.discover_feed(uri)
        end
      end

    end

  end

end