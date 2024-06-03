module NewsFetcher

  module Commands

    class Disable < Command

      def run(args)
        super
        @profile.find_subscriptions(ids: args).each do |subscription|
          subscription.disable
        end
      end

    end

  end

end