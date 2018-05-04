module NewsFetcher

  module Commands

    class Process < Command

      register_command 'process'

      attr_accessor :ignore_history
      attr_accessor :limit

      def run(args)
        @profile.subscriptions(args).each do |subscription|
          begin
            subscription.process(ignore_history: @ignore_history, limit: @limit)
          rescue Error => e
            warn "#{subscription.path}: #{e}"
          end
        end
      end

    end

  end

end