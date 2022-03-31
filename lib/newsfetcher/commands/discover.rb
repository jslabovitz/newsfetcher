module NewsFetcher

  module Commands

    class Discover < Command

      def run(args)
        super
        args.each do |uri|
          Subscriptions::Feed::Subscription.discover_feeds(uri).each do |subscription|
            subscription.print
          end
        end
      end

    end

  end

end