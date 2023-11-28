module NewsFetcher

  module Commands

    class Reset < Command

      def run(args)
        super
        @profile.find_subscriptions(ids: args).each(&:reset)
      end

    end

  end

end