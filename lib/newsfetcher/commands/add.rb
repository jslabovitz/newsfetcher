module NewsFetcher

  module Commands

    class Add < Command

      def run(args)
        super
        klass = SubscriptionClassForType[@type || 'feed'] \
          or raise Error, "Unknown subscription type: #{@type.inspect}"
        subscription = klass.make(args)
        @profile.add_subscription(subscription)
        warn "Added subscription: #{subscription.id}"
      end

    end

  end

end