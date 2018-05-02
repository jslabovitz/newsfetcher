module NewsFetcher

  module Commands

    class Fix < Command

      register_command 'fix'

      def run(args)
        @profile.feeds(args).each do |feed|
          feed.fix
        end
      end

    end

  end

end