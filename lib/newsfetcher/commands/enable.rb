module NewsFetcher

  module Commands

    class Enable < Command

      def run(args)
        super
        @profile.find_subscriptions(ids: args).each(&:enable)
      end

    end

  end

end