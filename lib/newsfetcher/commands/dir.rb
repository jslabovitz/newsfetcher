module NewsFetcher

  module Commands

    class Dir < Command

      def run(args)
        super
        @profile.find_subscriptions(ids: args).each do |subscription|
          puts subscription.dir
        end
      end

    end

  end

end