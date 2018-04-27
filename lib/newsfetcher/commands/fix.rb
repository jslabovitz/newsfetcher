module NewsFetcher

  module Commands

    class Fix < Command

      register_command 'fix'

      def run(args)
        @profile.feed_dirs_for_args(args).each do |feed_dir|
          feed = @profile.load_feed(feed_dir)
          feed.fix
        end
      end

    end

  end

end