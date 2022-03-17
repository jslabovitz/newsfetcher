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

        def title
          ps = PragmaticSegmenter::Segmenter.new(text: text)
          ps.segment.first
        end

        def text
          @tweet.full_text
            .sub(/^RT @(.+?)\s+/, '')
            .gsub(%r{https://t\.co/.*?$}, '')
            .strip
        end

        def to_html(show_header: true)
          Simple::Builder.html_fragment do |html|
            if show_header
              html.h2 do
                html.a(user, href: @tweet.uri)
              end
            end
            html.p { html << text.gsub("\n\n", '<p>').gsub("\n", '<br>') }
            if @tweet.retweet? || @tweet.quote?
              subtweet = self.class.new(@tweet.retweet? ? @tweet.retweeted_tweet : @tweet.quoted_tweet)
              html.div(class: 'blockquote') do
                html << subtweet.to_html
              end
            end
            if @tweet.media?    # && !@tweet.retweet?
              @tweet.media.each do |media|
                size = media.sizes[:large]
                html.figure do
                  html.a(href: media.expanded_uri) do
                    html.img(src: media.media_uri_https, width: size.w, height: size.h)
                  end
                  html.figcaption("[#{media.type}]")
                end
              end
            end
            if @tweet.uris? && !@tweet.quote?
              html.ul do
                @tweet.uris.each do |uri|
                  u = Addressable::URI.parse(uri.expanded_url)
                  html.li do
                    html.a(u.prettify, href: u)
                  end
                end
              end
            end
            if @replies.any?
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

end