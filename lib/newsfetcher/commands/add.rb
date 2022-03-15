module NewsFetcher

  module Commands

    class Add < Command

      def run(args)
        super
        uri, path = *args
        raise Error, "No URI specified" unless uri
        uri = Addressable::URI.parse(uri)
        subscription = Subscription.new(uri, path: path)
        @profile.add_subscription(subscription)
      end

    end

  end

end