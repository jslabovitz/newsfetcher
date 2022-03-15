module NewsFetcher

  class Subscription

    class Twitter

      class Tweet

        extend Forwardable

        def_delegators :@tweet,
          :uri,
          :created_at,
          :reply?

        attr_accessor :parent
        attr_accessor :replies

        def initialize(tweet)
          @tweet = tweet
          @parent = nil
          @replies = []
        end

        def id
          @tweet.id.to_s
        end

        def in_reply_to_status_id
          @tweet.in_reply_to_status_id.to_s
        end

        def user
          "#{@tweet.user.name} (@#{@tweet.user.screen_name})"
        end

        def text
          text = @tweet.full_text
          if text =~ /^RT @/
            ''
          else
            text.gsub(%r{https://t\.co/.*?$}, '').strip.gsub("\n", '<br>')
          end
        end

        def to_html
          Simple::Builder.html_fragment do |html|
            html.div(class: @parent ? 'tweet' : nil) do
              if @parent
                html.h2 do
                  html.a(user, href: @tweet.uri)
                end
              end
              html.div(class: 'tweet-text') do
                html.p do
                  html << text.gsub(%r{https://t\.co/.*?$}, '').strip.gsub("\n", '<br>')
                end
              end
              if @tweet.retweet? || @tweet.quote?
                subtweet = self.class.new(@tweet.retweet? ? @tweet.retweeted_tweet : @tweet.quoted_tweet)
                html << subtweet.to_html
              end
              if @tweet.media? && !@tweet.retweet?
                html.div(class: 'tweet-media') do
                  @tweet.media.each do |media|
                    html.a(href: media.uri) { html.img(src: media.media_uri) }
                  end
                end
              end
              if @tweet.uris? && !@tweet.quote?
                html.div(class: 'tweet-links') do
                  @tweet.uris.each do |uri|
                    u = Addressable::URI.parse(uri.expanded_url)
                    html.a(u.prettify, href: u)
                  end
                end
              end
              if @replies.any?
                @replies.each do |reply|
                  html << reply.to_html
                end
              end
            end
          end
        end

      end

    end

  end

end