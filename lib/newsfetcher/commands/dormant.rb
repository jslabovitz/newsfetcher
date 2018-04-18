module NewsFetcher

  module Commands

    class Dormant < Command

      register_command 'dormant',
        period: 30

      attr_accessor :period

      def run(args)
        @profile.select_feeds(args).each do |feed|
          days = feed.dormant_days
          if days.nil?
            puts "#{feed.id}: never modified"
          elsif days > @period
            puts "#{feed.id}: last modified #{days.to_i} days ago"
          end
        end
      end

    end

  end

end