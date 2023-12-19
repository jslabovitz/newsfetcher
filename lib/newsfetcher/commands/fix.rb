module NewsFetcher

  module Commands

    class Fix < Command

      def run(args)
        super
        @profile.find_subscriptions(ids: args).each do |subscription|
          subscription.fix
        end
      end

    end

  end

end