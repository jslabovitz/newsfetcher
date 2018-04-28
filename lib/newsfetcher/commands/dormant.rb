module NewsFetcher

  module Commands

    class Dormant < Command

      register_command 'dormant',
        period: 30

      attr_accessor :period

      def run(args)
        report = Hash[
          @profile.feed_dirs_for_args(args).map do |feed_dir|
            feed = @profile.load_feed(feed_dir)
            [feed.path, feed.dormant_days]
          end
        ]
        report.sort_by { |k, v| v }.reverse.each do |path, days|
          puts "%5s: %s" % [
            days ? ('%.1f' % days) : 'never',
            path,
          ]
        end
      end

    end

  end

end