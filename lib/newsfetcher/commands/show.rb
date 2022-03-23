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
          subscription.print(format: @details ? :list : :table)
        end
      end

    end

  end

end