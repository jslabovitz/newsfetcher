module NewsFetcher

  module Commands

    class Get < Command

      def run(args)
        super
        args.each do |uri|
          feed = Feed.get(uri)
          puts "URI: #{feed.uri}"
          puts "Title: #{feed.title.inspect}"
          puts "Items:"
          feed.items.values.each do |item|
            puts "\t" + "ID: #{item.id}"
            puts "\t" + "URI: #{item.uri}"
            puts "\t" + "Date: #{item.date}"
            puts "\t" + "Author: #{item.author}"
            puts "\t" + "Title: #{item.title}"
            puts
          end
          puts
        end
      end

    end

  end

end