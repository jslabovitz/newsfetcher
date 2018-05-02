module NewsFetcher

  module Commands

    class Process < Command

      register_command 'process'

      attr_accessor :ignore_history
      attr_accessor :limit

      def run(args)
        @profile.feeds(args).each do |feed|
          begin
            feed.process(ignore_history: @ignore_history, limit: @limit)
          rescue Error => e
            warn "#{feed.path}: #{e}"
          end
        end
      end

    end

  end

end