module NewsFetcher

  module Commands

    class AddTwitter < Command

      def run(args)
        super
        file, path = *args
        file = Path.new(file)
        config = Config.new(twitter: JSON.parse(file.read))
        subscription = Subscription::Twitter.new(
          id: 'twitter',
          config: config)
        @profile.add_subscription(subscription)
        warn "Added subscription: #{subscription.id}"
      end

    end

  end

end