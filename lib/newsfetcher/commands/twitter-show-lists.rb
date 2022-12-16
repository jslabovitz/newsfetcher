module NewsFetcher

  module Commands

    class TwitterShowLists < Command

      def run(args)
        super
        @profile.find_subscriptions(ids: args).
          select { |s| s.kind_of?(Subscriptions::Twitter::Subscription) }.
          each do |subscription|

          puts "#{subscription.id}:"
          subscription.show_lists
          puts
        end
      end

    end

  end

end