module NewsFetcher

  module Subscriptions

    module Twitter

      class Subscription < Base::Subscription

        def get
          @title = 'Twitter'
          @client = ::Twitter::REST::Client.new(@config.twitter)
          get_timeline
          find_threads
        end

        def get_timeline
          last_id = @history.latest_id&.to_i || 1
          @tweets = @client.
            home_timeline(since_id: last_id, tweet_mode: 'extended').
            map { |t| Tweet.new(t) }.
            sort_by(&:date)
        end

        def find_threads
          @tweets.each do |tweet|
            if (id = tweet.in_reply_to_status_id) && (parent = @tweets.find { |t| t.id == id })
              parent.replies << tweet
              tweet.parent = parent
            end
          end
          @items = @tweets.reject(&:parent).map { |t| Item.new(t) }
        end

      end

      class Item < Base::Item

        attr_accessor :tweet

        def initialize(tweet)
          @tweet = tweet
        end

        def printable
          super + [
            [:tweet, [@tweet]],
          ]
        end

        def id
          @tweet.id.to_s
        end

        def date
          @tweet.date
        end

        def title
          @tweet.title
        end

        def to_html
          @tweet.to_html
        end

      end

      class Tweet

        attr_accessor :parent
        attr_accessor :replies

        include Simple::Printer::Printable

        def initialize(tweet)
          @tweet = tweet
          @parent = nil
          @replies = []
        end

        def printable
          [
            [:id, 'ID'],
            [:uri, 'URI'],
            :title,
            :user,
            [:in_reply_to_status_id, 'Reply-To', in_reply_to_status_id],
            [:retweeted_tweet, 'Retweeted', retweeted_tweet&.id],
            [:quoted_tweet, 'Quoted', quoted_tweet&.id],
            [:parent, @parent&.id],
            [:replies, 'Replies', @replies.map(&:id).join(', ')],
          ]
        end

        def id
          @id ||= @tweet.id
        end

        def date
          @tweet.created_at
        end

        def uri
          @uri ||= Addressable::URI.parse(@tweet.uri)
        end

        def in_reply_to_status_id
          @tweet.in_reply_to_status_id
        end

        def user
          @user ||= "#{@tweet.user.name} (@#{@tweet.user.screen_name})"
        end

        def title
          unless @title
            if text.empty?
              @title = subtweet&.title
            else
              @title = PragmaticSegmenter::Segmenter.new(text: text).segment.first.to_s
              @title = @title.empty? ? '(untitled)' : @title
              if @tweet.retweet?
                @title = "Retweet: #{@title}"
              elsif @tweet.quote?
                @title = "Quote: #{@title}"
              elsif @tweet.reply?
                @title = "Reply: #{@title}"
              end
            end
          end
          @title
        end

        def text
          @text ||= @tweet.full_text
            .sub(/^RT @.*/, '')
            .gsub(%r{https://t\.co/.*?$}, '')
            .strip
        end

        def retweeted_tweet
          (t = @tweet.retweet?) ? self.class.new(@tweet.retweeted_tweet) : nil
        end

        def quoted_tweet
          (t = @tweet.quote?) ? self.class.new(@tweet.quoted_tweet) : nil
        end

        def subtweet
          retweeted_tweet || quoted_tweet
        end

        def to_html
          Simple::Builder.html_fragment do |html|
            html.h2 do
              html.a(user, href: @tweet.uri)
            end
            unless @tweet.retweet?
              html.p do
                html << text.gsub("\n", '<br>')
              end
            end
            if @tweet.retweet? || @tweet.quote?
              html.div(class: 'blockquote') do
                html << subtweet.to_html
              end
            else
              if @tweet.media?
                @tweet.media.each do |media|
                  size = media.sizes[:large]
                  html.figure do
                    html.figcaption("[#{media.type}]")
                    html.a(href: media.expanded_uri) do
                      html.img(src: media.media_uri_https, width: size.w, height: size.h)
                    end
                  end
                end
              end
              if @tweet.uris?
                html.ul do
                  @tweet.uris.each do |uri|
                    u = Addressable::URI.parse(uri.expanded_url)
                    html.li do
                      html.a(u.prettify, href: u)
                    end
                  end
                end
              end
            end
            @replies.each do |reply|
              html.hr
              html << reply.to_html
            end
          end
        end

      end

    end

  end

end