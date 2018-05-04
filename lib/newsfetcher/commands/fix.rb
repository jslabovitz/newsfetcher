module NewsFetcher

  module Commands

    class Fix < Command

      register_command 'fix'

      def run(args)
        @profile.subscriptions(args).each do |subscription|
          subscription.fix
        end
      end

    end

  end

end