module NewsFetcher

  module Commands

    class Update < Command

      def run(args)
        super
        subscriptions = @profile.find_subscriptions(ids: args)
        if @profile.config.max_threads == 0
          subscriptions.each(&:update)
        else
          run_threads(subscriptions, &:update)
        end
      end

      def run_threads(objects, &block)
        threads = []
        objects.each do |object|
          if threads.length >= @profile.config.max_threads
            $logger.debug { "Waiting for #{threads.length} threads to finish" }
            threads.map(&:join)
            threads = []
          end
          threads << Thread.new do
            $logger.debug { "Started thread for #{object.id}" }
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