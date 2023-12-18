module NewsFetcher

  module Commands

    class Disable < Command

      def run(args)
        super
        @profile.find_subscriptions(ids: args).each do |subscription|
          subscription.disabled = true
          subscription.save
        end
      end

    end

  end

end