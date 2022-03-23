module NewsFetcher

  module Commands

    class Edit < Command

      def run(args)
        super
        @profile.find_subscriptions(ids: args).each do |subscription|
          subscription.edit
        end
      end

    end

  end

end