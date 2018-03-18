module Feeder

  module Commands

    class Add < Command

      register_command 'add'

      def run(args)
        raise Error, "No profile specified" unless @profile
        feed_link = args.shift or raise "No feed URI specified"
        path = args.shift or raise "No path specified"
        feed_link = URI.parse(feed_link)
        response = Feeder.get(feed_link)
        raise Error, "Failed to get URI #{feed_link}: #{response.status}" unless response.success?
        begin
          jira_feed = Feedjira::Feed.parse(response.body)
        rescue Feedjira::NoParserAvailable => e
          feeds = find_feeds(response.body)
          raise Error, "No alternate links in URI: #{feed_link}" if feeds.empty?
          feeds.each do |uri, type, title|
            puts "%s (%s): %s" % [uri, type, title]
          end
          return
        end
        #FIXME: save feed
        feed = Feed.new(
          id: [path, Feeder.uri_to_key(feed_link)].compact.join('/'),
          feed_link: feed_link,
          profile: @profile)
        feed.save
        ;;warn "saved new feed to #{feed.info_file}"
      end

      def find_feeds(html_str)
        html = Nokogiri::HTML::Document.parse(html_str)
        html.xpath('//link[@rel="alternate"]').map do |link_elem|
          [
            # feed_link + URI.parse(link_elem['href']),
            link_elem['href'],
            link_elem['type'],
            link_elem['title'],
          ]
        end
      end

    end

  end

end