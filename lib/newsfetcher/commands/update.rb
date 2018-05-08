module NewsFetcher

  module Commands

    class Update < Command

      register_command 'update',
        limit: 100

      attr_accessor :limit

      def run(args)
        @profiles.each do |profile|
          profile.update_subscriptions(args, limit: @limit)
        end
      end

    end

  end

end