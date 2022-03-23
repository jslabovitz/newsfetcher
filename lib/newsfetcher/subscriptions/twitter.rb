module NewsFetcher

  module Subscriptions

    module Twitter

      class Subscription < Base::Subscription

        def get
          @title = 'Twitter'
          @client = ::Twitter::REST::Client.new(@config.twitter)
          get_timeline.each do |tweet|
            if tweet.reply? && (parent_item = @items.find { |i| i.id == tweet.in_reply_to_status_id })
              tweet.parent = parent_item.object
              tweet.parent.replies << tweet
            else
              @items << Item.new(tweet)
            end
          end
        end

        def get_timeline
          params = {
            since_id: @history.latest_id || 1,
            tweet_mode: 'extended',
          }
          @client.home_timeline(params).map { |t| Tweet.new(t) }.sort_by(&:created_at)
        end

      end

      class Item < Base::Item

        def id
          @id ||= @object.id.to_s
        end

        def published
          @published ||= @object.created_at
        end

        def summary
          @summary ||= @object.summary
        end

        def title
          nil
        end

        def uri
          @uri ||= Addressable::URI.parse(@object.uri)
        end

        def author
          @author ||= @object.user
        end

        def content
          @content ||= @object.to_html(show_header: false)
        end

      end

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
          @id ||= @tweet.id.to_s
        end

        def in_reply_to_status_id
          @tweet.in_reply_to_status_id.to_s
        end

        def user
          @user ||= "#{@tweet.user.name} (@#{@tweet.user.screen_name})"
        end

        def summary
          if text.empty?
            subtweet&.summary
          else
            summary = PragmaticSegmenter::Segmenter.new(text: text).segment.first.to_s
            summary = summary.empty? ? '(untitled)' : summary
            if @tweet.retweet?
              "Retweet: #{summary}"
            elsif @tweet.quote?
              "Quote: #{summary}"
            elsif @tweet.reply?
              "Reply: #{summary}"
            else
              summary
            end
          end
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

        def to_html(show_header: true)
          Simple::Builder.html_fragment do |html|
            if show_header
              html.h2 do
                html.a(user, href: @tweet.uri)
              end
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