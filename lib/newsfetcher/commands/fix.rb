module NewsFetcher

  module Commands

    class Fix < Command

      def run(args)
        super
        @profile.find_subscriptions(ids: args).each(&:fix)
      end

    end

  end

end