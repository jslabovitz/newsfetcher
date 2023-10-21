module NewsFetcher

  module Commands

    class Update < Command

      def run(args)
        super
        run_threads(@profile.find_subscriptions(ids: args)) { |s| @profile.update_subscription(s) }
      end

      def run_threads(objects, &block)
        threads = []
        objects.each do |object|
          if @profile.config.max_threads > 1
            if threads.length >= @profile.config.max_threads
              $logger.debug { "Waiting for #{threads.length} threads to finish" }
              threads.map(&:join)
              threads = []
            end
            threads << Thread.new do
              $logger.debug { "Started thread for #{object.id}" }
              yield(object)
            end
          else
            yield(object)
          end
        end
        unless threads.empty?
          $logger.debug { "Waiting for last #{threads.length} threads to finish" }
          threads.map(&:join)
        end
      end
    end

  end

end