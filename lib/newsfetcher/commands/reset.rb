module NewsFetcher

  module Commands

    class Reset < Command

      def run(args)
        super
        @profile.find_subscriptions(ids: args).each do |subscription|
          subscription.reset
        end
      end

    end

  end

end