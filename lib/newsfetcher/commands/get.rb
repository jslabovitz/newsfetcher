module NewsFetcher

  module Commands

    class Get < Command

      def run(args)
        super
        args.each do |uri|
          resource = Resource.get(uri)
          feed = Feed.new_from_resource(resource)
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