module NewsFetcher

  module Commands

    class Discover < Command

      def run(args)
        super
        args.each do |uri|
          Subscription.discover_feeds(uri).each do |subscription|
            puts "URI: #{subscription.config.uri}"
            puts "Title: #{subscription.title.inspect}"
            puts
          end
        end
      end

    end

  end

end