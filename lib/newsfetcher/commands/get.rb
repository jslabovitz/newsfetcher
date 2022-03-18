module NewsFetcher

  module Commands

    class Get < Command

      def run(args)
        super
        @profile.find_subscriptions(ids: args).each do |subscription|
          subscription.get
          subscription.print(format: :list)
          subscription.items.each do |item|
            item.show
            puts
          end
          puts
        end
      end

    end

  end

end