module NewsFetcher

  class Subscription

    class Twitter

      class Timeline

        def initialize(config)
          @client = ::Twitter::REST::Client.new(config)
        end

        def fetch(since_id: nil)
          params = {
            since_id: since_id || 1,
            trim_user: true,
          }
          @tweets = @client.home_timeline(params).map { |t| get_tweet(t.id) }.sort_by(&:created_at)
          @tweets.each do |tweet|
            if tweet.reply?
              tweet.parent = get_tweet(tweet.in_reply_to_status_id)
              tweet.parent.replies << tweet
            end
          end
          @tweets.reject(&:parent)
        end

        def get_tweet(id)
          Tweet.new(@client.status(id, tweet_mode: 'extended'))
        end

      end

    end

  end

end