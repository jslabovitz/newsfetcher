module NewsFetcher

  module Commands

    class TwitterShowListMembers < Command

      def run(args)
        super
        @profile.find_subscriptions(ids: args).
          select { |s| s.kind_of?(Subscriptions::Twitter::Subscription) }.
          each do |subscription|

          puts "#{subscription.id}:"
          subscription.show_list_members
          puts
        end
      end

    end

  end

end