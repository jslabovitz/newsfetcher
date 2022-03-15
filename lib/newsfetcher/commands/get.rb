module NewsFetcher

  module Commands

    class Get < Command

      def run(args)
        super
        args.each do |uri|
          uri = Addressable::URI.parse(uri)
          subscription = Subscription::Feed.new(
            id: Subscription.uri_to_id(uri),
            config: Config.new(uri: uri))
          subscription.get
          subscription.print(format: :list)
          subscription.items.each do |item|
            item.show
            puts
          end
          puts
        end
      end

    end

  end

end