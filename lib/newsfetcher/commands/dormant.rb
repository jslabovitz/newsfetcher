module NewsFetcher

  module Commands

    class Dormant < Command

      register_command 'dormant',
        period: 30

      attr_accessor :period

      def run(args)
        @profile.feed_dirs_for_args(args).each do |feed_dir|
          feed = @profile.load_feed(feed_dir)
          days = feed.dormant_days
          if days.nil?
            puts "#{feed.path}: never modified"
          elsif days > @period
            puts "#{feed.path}: last modified %.1f days ago" % days
          end
        end
      end

    end

  end

end