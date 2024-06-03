module NewsFetcher

  module Commands

    class Enable < Command

      def run(args)
        super
        @profile.find_subscriptions(ids: args).each do |subscription|
          subscription.enable
        end
      end

    end

  end

end