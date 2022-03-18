module NewsFetcher

  class Subscription

    class Twitter < Subscription

      def get
        @title = 'Twitter'
        @client = ::Twitter::REST::Client.new(@config.twitter)
        get_timeline.each do |tweet|
          # if tweet.reply?
          #   tweet.parent = get_tweet(tweet.in_reply_to_status_id)
          #   tweet.parent.replies << tweet
          #   next
          # end
          @items << Item.new(
            id: tweet.id,
            published: tweet.created_at,
            title: tweet.title,
            uri: Addressable::URI.parse(tweet.uri),
            author: tweet.user,
            content: tweet.to_html(show_header: false),
          )
        end
      end

      def get_timeline
        params = {
          since_id: @history.latest_id || 1,
          tweet_mode: 'extended',
        }
        @client.home_timeline(params).map { |t| Tweet.new(t) }.sort_by(&:created_at)
      end

      def get_tweet(id)
        Tweet.new(@client.status(id, tweet_mode: 'extended'))
      end

    end

  end

end