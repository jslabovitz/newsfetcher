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
          latest_key, latest_time = @history.latest_entry
          last_id = latest_key&.to_i || 1
          @items = @client.
            home_timeline(count: 200, since_id: last_id, tweet_mode: 'extended').
            map { |t| Item.new(t) }
          @items.sort_by!(&:date)
        end

        def find_threads
          @items.each do |item|
            if (id = item.in_reply_to_status_id) && (parent = @items.find { |i| i.id == id })
              parent.replies << item
              item.parent = parent
            end
          end
          @items.reject!(&:has_parent?)
        end

        def filter_items
          super
          @items.reject! do |item|
            config = item_config(item)
            if (subtweet = item.subtweet)
              # if config.ignore_subtweets
              #   $logger.info { "#{@id}: Ignoring item with subtweet: #{item.id}" }
              #   next true
              # end
              # if item.screen_name == subtweet.screen_name
              #   $logger.info { "#{@id}: Ignoring item with subtweet of self: #{item.id}" }
              #   next true
              # end
            end
            false
          end
        end

        def item_config(item)
          if @config.has_key?(:users) && (user_config = @config.users[item.screen_name])
            @config.make(user_config)
          else
            @config
          end
        end

      end

      class Item < Base::Item

        attr_accessor :tweet
        attr_accessor :parent
        attr_accessor :replies

        def initialize(tweet)
          super(
            id: tweet.id.to_s,
            date: tweet.created_at,
            # title: tweet.title,
            uri: Addressable::URI.parse(tweet.uri),
            author: "#{tweet.user.name} (@#{tweet.user.screen_name})",
            tweet: tweet,
            replies: [],
          )
        end

        def printable
          super + [
            [:in_reply_to_status_id, 'Reply-To', in_reply_to_status_id],
            [:retweeted_tweet, 'Retweeted', retweeted_tweet&.id],
            [:quoted_tweet, 'Quoted', quoted_tweet&.id],
            [:parent, @parent&.id],
            [:replies, 'Replies', @replies.map(&:id).join(', ')],
          ]
        end

        def has_parent?
          @parent != nil
        end

        def in_reply_to_status_id
          @tweet.in_reply_to_status_id
        end

        def user_name
          @tweet.user.name
        end

        def screen_name
          @tweet.user.screen_name
        end

        def title
          unless @title
            if text.empty?
              @title = subtweet&.title
            else
              @title = PragmaticSegmenter::Segmenter.new(text: text).segment.first.to_s
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

        def to_html(show_header: true)
          Simple::Builder.html_fragment do |html|
            if show_header
              html.h2 do
                html.a(@author, href: @tweet.uri)
              end
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
                    html.img(src: media.media_uri_https, width: size.w, height: size.h)
                    unless media.type == 'photo'
                      html.figcaption do
                        html << "#{media.type}: "
                        html.a(Addressable::URI.parse(media.expanded_uri).prettify, href: media.expanded_uri)
                      end
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
              html << reply.to_html(show_header: false)
            end
          end
        end

      end

    end

  end

end