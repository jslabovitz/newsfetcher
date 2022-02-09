module NewsFetcher

  module Commands

    class Discover < Command

      def run(args)
        super
        args.each do |uri|
          @profile.discover_feeds(uri).each do |feed|
            puts "URI: #{feed.uri}"
            puts "Title: #{feed.title.inspect}"
            puts
          end
        end
      end

    end

  end

end