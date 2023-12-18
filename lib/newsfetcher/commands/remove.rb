module NewsFetcher

  module Commands

    class Remove < Command

      def run(args)
        super
        @profile.find_subscriptions(ids: args).each do |subscription|
          dir = subscription.dir or raise Error, "dir not set"
          dir.rmtree
        end
      end

    end

  end

end