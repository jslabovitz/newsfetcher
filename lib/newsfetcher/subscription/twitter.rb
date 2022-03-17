module NewsFetcher

  class Subscription

    class Twitter < Subscription

      def get
        @title = 'Twitter'
        @timeline = Timeline.new(@config.twitter)
        @items = @timeline.fetch(since_id: @history.latest_id).map { |t| item_for_tweet(t) }
      end

      def item_for_tweet(tweet)
        Item.new(
          id: tweet.id,
          published: tweet.created_at,
          title: tweet.title,
          uri: Addressable::URI.parse(tweet.uri),
          author: tweet.user,
          content: tweet.to_html(show_header: false),
        )
      end

    end

  end

end