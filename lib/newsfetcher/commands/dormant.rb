module NewsFetcher

  module Commands

    class Dormant < Command

      register_command 'dormant',
        period: 30

      attr_accessor :period

      def run(args)
        @profiles.each do |profile|
          puts "#{profile.id}:"
          profile.dormancy_report(args, period: @period).each do |subscription_id, days|
            puts "\t%5s: %s" % [
              days ? days.to_i : 'never',
              subscription_id,
            ]
          end
        end
      end

    end

  end

end