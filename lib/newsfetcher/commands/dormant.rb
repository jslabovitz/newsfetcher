module NewsFetcher

  module Commands

    class Dormant < Command

      register_command 'dormant',
        period: 30

      attr_accessor :period

      def run(args)
        report = Hash[
          @profile.subscriptions(args).map do |subscription|
            [subscription.path, subscription.dormant_days]
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