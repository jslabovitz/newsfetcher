module NewsFetcher

  module Commands

    class Get < Command

      def run(args)
        super
        @profile.find_subscriptions(ids: args).each do |subscription|
          subscription.get
          subscription.print
        end
      end

    end

  end

end