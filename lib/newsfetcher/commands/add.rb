module NewsFetcher

  module Commands

    class Add < Command

      def run(args)
        super
        klass = SubscriptionClassForType[@type || 'feed'] \
          or raise Error, "Unknown subscription type: #{@type.inspect}"
        uri, path, id = *args
        raise Error, "No URI specified" unless uri
        uri = Addressable::URI.parse(uri)
        subscription = klass.new(
          id: Subscriptions::Feed::Subscription.make_id(uri: uri, id: id, path: path),
          config: Config.new(uri: uri))
        @profile.add_subscription(subscription)
        warn "Added subscription: #{subscription.id}"
      end

    end

  end

end