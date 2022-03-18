module NewsFetcher

  class Subscription

    class Feed < Subscription

      def self.uri_to_id(uri, path: nil)
        uri = Addressable::URI.parse(uri)
        id = [
          uri.host.to_s \
            .sub(/^(www|ssl|en|feeds|rss|blogs?|news).*?\./i, '') \
            .sub(/\.(com|org|net|info|edu|co\.uk|wordpress\.com|blogspot\.com|feedburner\.com)$/i, ''),
          uri.path.to_s \
            .gsub(/\b(\.?feeds?|index|atom|rss|rss2|xml|rdf|php|blog|posts|default)\b/i, ''),
          uri.query.to_s \
            .gsub(/\b(format|feed|type|q)=(atom|rss\.xml|rss2?|xml)/i, ''),
        ] \
          .join(' ')
          .downcase
          .gsub(/[^a-z0-9]+/, ' ')  # non-alphanumeric
          .strip
          .gsub(/\s+/, '-')
        id = "#{path}/#{id}" if path
        id
      end

      def self.discover_feeds(uri, path: nil)
        uri = Addressable::URI.parse(uri)
        raise Error, "Bad URI: #{uri}" unless uri.absolute?
        begin
          resource = Resource.get(uri)
        rescue Error => e
          raise Error, "Failed to get #{uri}: #{e}"
        end
        html = Nokogiri::HTML::Document.parse(resource.content)
        html.xpath('//link[@rel="alternate"]').select { |link| FeedTypes.include?(link['type']) }.map do |link|
          feed_uri = uri.join(link['href'])
          new(
            id: uri_to_id(feed_uri, path: path),
            config: Config.new(uri: feed_uri))
        end
      end

      def get
        resource = Resource.get(@config.uri)
        if resource.moved && !@config.ignore_moved
          $logger.warn { "#{@id}: URI #{resource.uri} moved to #{resource.redirected_uri}" }
        end
        Feedjira.configure { |c| c.strip_whitespace = true }
        begin
          feedjira = Feedjira.parse(resource.content.force_encoding(Encoding::UTF_8))
        rescue StandardError, Feedjira::NoParserAvailable, Date::Error => e
          raise Error, "Can't parse XML feed from #{resource.uri}: #{e}"
        end
        @title = feedjira.title
        @items = feedjira.entries.map { |e| item_for_entry(e) }
      end

      def item_for_entry(entry)
        uri = nil
        if entry.url
          begin
            uri = Addressable::URI.parse(entry.url.strip)
          rescue Addressable::URI::InvalidURIError => e
            raise Error, "Can't parse URL for entry: #{entry.url.inspect}"
          end
        end
        id = entry.entry_id
        unless id
          raise Error, "No ID or URL for entry" unless uri
          if uri.scheme == 'http' || uri.scheme == 'https'
            uri.host = uri.host.sub(/^www\./, '')
          end
          id = uri.to_s
        end
        Item.new(
          id: id,
          published: entry.published || Time.now,
          title: entry.title,
          uri: uri,
          author: entry.respond_to?(:author) ? entry.author&.sub(/^by\s+/i, '') : nil,
          content: render_content(entry.content || entry.summary || ''),
        )
      end

    end

  end

end