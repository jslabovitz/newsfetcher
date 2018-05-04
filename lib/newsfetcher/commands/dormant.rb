module NewsFetcher

  module Commands

    class Dormant < Command

      register_command 'dormant',
        period: 30

      attr_accessor :period

      def run(args)
        @profile.dormancy_report(args, period: @period).each do |path, days|
          puts "%5s: %s" % [
            days ? days.to_i : 'never',
            path,
          ]
        end
      end

    end

  end

end