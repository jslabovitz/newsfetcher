module NewsFetcher

  class Subscription

    class Twitter

      class Timeline

        def initialize(config)
          @client = ::Twitter::REST::Client.new(config)
          @tweets = {}
        end

        def fetch
          @client.home_timeline(since_id: last_id, trim_user: true).each do |obj|
            get_tweet(obj.id)
          end
          find_threads
          @tweets.values.sort_by(&:id).reject(&:parent)
        end

        def last_id
          @tweets.values.map(&:id).max || 1
        end

        def get_tweet(id)
          unless (tweet = @tweets[id])
            tweet = Tweet.new(@client.status(id, tweet_mode: 'extended'))
            @tweets[tweet.id] = tweet
          end
          tweet
        end

        def find_threads
          @tweets.values.sort_by(&:id).each do |tweet|
            if tweet.reply?
              tweet.parent = get_tweet(tweet.in_reply_to_status_id)
              tweet.parent.replies << tweet
            end
          end
        end

      end

    end

  end

end