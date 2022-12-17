module NewsFetcher

  module Subscriptions

    module Twitter

      class Subscription < Base::Subscription

        def initialize(**)
          super
          @title = 'Twitter'
          if @config.has_key?(:users)
            @user_configs = @config.users.map { |n, c| [n, @config.make(c)] }.to_h
          else
            @user_configs = {}
          end
        end

        def client
          @client ||= ::Twitter::REST::Client.new(@config.twitter)
        end

        def show_lists
          client.lists.each do |list|
            %i[
              id
              uri
              name
              full_name
              slug
              description
              member_count
              subscriber_count
              created_at
              mode
              user
            ].each do |key|
              puts '%16s: %s' % [key, list.send(key)]
            end
            puts '%16s: %s' % ['user_id', list.user.id]
            puts
          end
        end

        def show_list_members
          raise Error, "Not configured for list" unless @config.list_timeline
          client.list_members(**@config.list_timeline).each do |member|
            puts "\t" + member.screen_name
          end
        end

        def get
          latest_key, latest_time = @history.latest_entry
          last_id = latest_key&.to_i || 1
          params = { count: 200, since_id: last_id, tweet_mode: 'extended' }
          if @config.list_timeline
            tweets = client.list_timeline(**@config.list_timeline, **params)
          else
            tweets = client.home_timeline(**params)
          end
          @items = tweets.map { |t| Item.new(t) }
        end

        def process
          @items.each do |item|
            if (id = item.in_reply_to_status_id) && (parent = @items.find { |i| i.id == id })
              parent.replies << item
              item.parent = parent
            end
          end
          @items.reject! { |item| reject_item?(item) }
        end

        def reject_item?(item)
          return true if item.has_parent?
          config = @user_configs[item.screen_name] || @config
          if config.ignore_text
            if item.text =~ Regexp.new(config.ignore_text, Regexp::IGNORE_CASE)
              $logger.info { "#{@id}: Ignoring item based on text: #{item.id}" }
              return true
            end
          end
          if item.subtweet
            if config.ignore_subtweets
              $logger.info { "#{@id}: Ignoring item with subtweet: #{item.id}" }
              return true
            end
            if config.ignore_self_subtweets && item.screen_name == item.subtweet.screen_name
              $logger.info { "#{@id}: Ignoring item with subtweet of self: #{item.id}" }
              return true
            end
          end
          if config.ignore_quote_tweets && item.quoted_tweet
            if !config.ignore_quote_tweets_length
              $logger.info { "#{@id}: Ignoring item with quoted tweet: #{item.id}" }
              return true
            end
            if item.text.length < config.ignore_quote_tweets_length
              $logger.info { "#{@id}: Ignoring item with short quoted tweet: #{item.id}" }
              return true
            end
          end
          if config.ignore_retweets && item.retweeted_tweet
            $logger.info { "#{@id}: Ignoring item with retweet: #{item.id}" }
            return true
          end
          false
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
          @tweet.in_reply_to_status_id&.to_s
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
          @retweeted_tweet ||= (@tweet.retweet? ? self.class.new(@tweet.retweeted_tweet) : nil)
        end

        def quoted_tweet
          @quoted_tweet ||= (@tweet.quote? ? self.class.new(@tweet.quoted_tweet) : nil)
        end

        def subtweet
          @subtweet ||= (retweeted_tweet || quoted_tweet)
        end

        def to_html(show_header: true)
          Simple::Builder.html_fragment do |html|
            if show_header
              html.h2 do
                html.a(@author, href: @tweet.uri)
              end
            end
            html.p { html << text.gsub("\n", '<br>') }
            if subtweet
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