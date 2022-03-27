module NewsFetcher

  module Subscriptions

    module Twitter

      class Subscription < Base::Subscription

        def get
          @title = 'Twitter'
          client = ::Twitter::REST::Client.new(@config.twitter)
          params = {
            since_id: @history.latest_id || 1,
            tweet_mode: 'extended',
          }
          client.home_timeline(params).map { |t| Tweet.new(t) }.sort_by(&:created_at).each do |tweet|
            if tweet.reply? && (parent_item = @items.find { |i| i.id == tweet.in_reply_to_status_id })
              tweet.parent = parent_item.object
              tweet.parent.replies << tweet
            else
              @items << Item.new(tweet)
            end
          end
        end

      end

      class Item < Base::Item

        def id
          @id ||= @object.id.to_s
        end

        def published
          @object.created_at
        end

        def title
          @object.title
        end

        def uri
          @object.uri
        end

        def author
          @object.user
        end

        def to_html
          @object.to_html
        end

      end

      class Tweet

        extend Forwardable

        def_delegators :@tweet,
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
          @id ||= @tweet.id.to_s
        end

        def uri
          @uri ||= Addressable::URI.parse(@tweet.uri)
        end

        def in_reply_to_status_id
          @tweet.in_reply_to_status_id.to_s
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
            unless (t = text).empty?
              html.p do
                html << t.gsub("\n", '<br>')
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