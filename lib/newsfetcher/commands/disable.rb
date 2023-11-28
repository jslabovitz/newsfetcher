module NewsFetcher

  module Commands

    class Disable < Command

      def run(args)
        super
        @profile.find_subscriptions(ids: args).each(&:disable)
      end

    end

  end

end