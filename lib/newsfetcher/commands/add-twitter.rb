module NewsFetcher

  module Commands

    class AddTwitter < Command

      def run(args)
        super
        id, config_file = *args
        config_file = Path.new(config_file)
        config = Config.new(twitter: JSON.parse(config_file.read))
        subscription = Subscriptions::Twitter::Subscription.new(id: id, config: config)
# ;;subscription.show_lists; exit
        @profile.add_subscription(subscription)
        warn "Added subscription: #{subscription.id}"
      end

    end

  end

end