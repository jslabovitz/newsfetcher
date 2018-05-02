module NewsFetcher

  module Commands

    class Update < Command

      register_command 'update'

      attr_accessor :ignore_history
      attr_accessor :limit

      def run(args)
        @profile.feeds(args).each do |feed|
          feed.update
          feed.process(ignore_history: @ignore_history, limit: @limit)
        end
      end

    end

  end

end