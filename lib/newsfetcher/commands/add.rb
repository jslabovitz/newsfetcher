module NewsFetcher

  module Commands

    class Add < Command

      def run(args)
        super
        uri, path, id = *args
        raise Error, "No URI specified" unless uri
        uri = Addressable::URI.parse(uri)
        subscription = Subscription.make(uri: uri, id: id, path: path)
        @profile.add_subscription(subscription)
        warn "Added subscription: #{subscription.id}"
      end

    end

  end

end