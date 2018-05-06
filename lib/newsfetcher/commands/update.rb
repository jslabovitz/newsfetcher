module NewsFetcher

  module Commands

    class Update < Command

      register_command 'update',
        limit: 100

      attr_accessor :limit

      def run(args)
        threads = []
        @profile.subscriptions(args).each do |subscription|
          if threads.length >= @limit
            # ;;warn "waiting for #{threads.length} threads to finish"
            threads.map(&:join)
            threads = []
          end
          threads << Thread.new do
            # ;;warn "started thread for #{subscription.id}"
            begin
              subscription.update
            rescue Error => e
              warn "#{subscription.id}: #{e}"
            end
          end
        end
        # ;;warn "waiting for last #{threads.length} threads to finish"
        threads.map(&:join)
      end

    end

  end

end