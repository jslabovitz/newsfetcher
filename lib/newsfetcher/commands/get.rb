module NewsFetcher

  module Commands

    class Get < Command

      def run(args)
        super
        args.each do |uri|
          resource = Resource.get(uri)
          subscription = Subscription.new_from_resource(resource)
          puts "URI: #{subscription.uri}"
          puts "Title: #{subscription.title.inspect}"
          puts "Items:"
          subscription.items.each do |item|
            puts "\t" + "ID: #{item.id}"
            puts "\t" + "URI: #{item.uri}"
            puts "\t" + "Published: #{item.published}"
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