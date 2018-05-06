module NewsFetcher

  module Commands

    class Update < Command

      register_command 'update'

      def run(args)
        @profile.subscriptions(args).each do |subscription|
          begin
            subscription.update
          rescue Error => e
            warn "#{subscription.id}: #{e}"
          end
        end
      end

    end

  end

end