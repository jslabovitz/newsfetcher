module NewsFetcher

  module Commands

    class Show < Command

      def run(args)
        super
        @profile.find_subscriptions(
          ids: args,
          status: @status ? @status.split(',').map(&:to_sym) : nil,
          sort: @sort&.to_sym,
        ).each do |subscription|
          subscription.print
          puts
        end
      end

    end

  end

end