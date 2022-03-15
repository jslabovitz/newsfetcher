module NewsFetcher

  module Commands

    class Add < Command

      def run(args)
        super
        uri, path = *args
        raise Error, "No URI specified" unless uri
        uri = Addressable::URI.parse(uri)
        subscription = Subscription.new(
          id: Subscription.name_to_id(uri, path: path),
          config: Config.new(uri: uri))
        @profile.add_subscription(subscription)
        warn "Added subscription: #{subscription.id}"
      end

    end

  end

end