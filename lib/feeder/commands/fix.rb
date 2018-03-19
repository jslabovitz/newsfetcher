module Feeder

  module Commands

    class Fix < Command

      register_command 'fix'

      def run(args)
        @profile.each_feed(args) do |feed|
          feed.fix
        end
      end

    end

  end

end