module Feeder

  module Commands

    class Update < Command

      register_command 'update'

      attr_accessor :ignore_history
      attr_accessor :limit

      def run(args)
        threads = []
        @profile.each_feed(args) do |feed|
          threads << Thread.new do
            begin
              feed.update(ignore_history: @ignore_history, limit: @limit)
            rescue Error => e
              warn "#{feed.id}: #{e}"
              Thread.exit
            end
          end
        end
        threads.map(&:join)
      end

    end

  end

end