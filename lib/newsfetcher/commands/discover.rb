module NewsFetcher

  module Commands

    class Discover < Command

      def run(args)
        super
        args.each do |uri|
          @profile.discover_feed(uri).each do |info|
            puts "URI: #{info[:uri]}"
            puts "Type: #{info[:type]}"
            puts "Title: #{info[:title].inspect}"
            puts
          end
        end
      end

    end

  end

end