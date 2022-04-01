module NewsFetcher

  module Subscriptions

    module Feed

      class Subscription < Base::Subscription

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
          @items = feedjira.entries.map { |e| Item.new(e) }
        end

        def active_items
          if @config.ignore
            ignore_patterns = [@config.ignore].flatten.map { |r| Regexp.new(r) }
            super.reject do |item|
              ignore_patterns.find { |r| item.uri.to_s =~ r }
            end
          else
            super
          end
        end

      end

      class Item < Base::Item

        def id
          unless @id
            @id = @object.entry_id
            unless @id
              raise Error, "No ID or URL for entry" unless uri
              # if uri.scheme == 'http' || uri.scheme == 'https'
              #   uri = uri.dup
              #   uri.host = uri.host.sub(/^www\./, '')
              # end
              @id = uri.to_s
            end
          end
          @id
        end

        def date
          @date ||= (@object.published || Time.now)
        end

        def title
          @title ||= @object.title
        end

        def uri
          unless @uri
            if @object.url
              begin
                @uri = Addressable::URI.parse(@object.url.strip)
              rescue Addressable::URI::InvalidURIError => e
                raise Error, "Can't parse URL for entry: #{@object.url.inspect}"
              end
            end
          end
          @uri
        end

        def author
          @author ||= @object.respond_to?(:author) ? @object.author&.sub(/^by\s+/i, '') : nil
        end

        def to_html
          Simple::Builder.html_fragment do |html|
            if title
              html.h1 do
                html << title.to_html
              end
            end
            html.h2 do
              html << [date_str, author].compact.join(' • ').to_html
            end
            if uri
              html.h3 do
                html.a(uri.prettify, href: uri)
              end
            end
            content = @object.content || @object.summary
            if content&.html?
              html << scrub_html(content)
            elsif content
              html << text_to_html(content)
            end
          end
        end

      end

    end

  end

end