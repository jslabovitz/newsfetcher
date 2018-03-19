module Feeder

  module Commands

    class Update < Command

      register_command 'update'

      attr_accessor :ignore_history
      attr_accessor :limit

      def run(args)
        @profile.update_feeds(@profile.select_feeds(args), ignore_history: @ignore_history, limit: @limit)
      end

    end

  end

end