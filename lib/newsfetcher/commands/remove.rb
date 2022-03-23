module NewsFetcher

  module Commands

    class Remove < Command

      def run(args)
        super
        @profile.find_subscriptions(ids: args).each do |subscription|
          subscription.remove
        end
      end

    end

  end

end