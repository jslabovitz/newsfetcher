module NewsFetcher

  module Subscriptions

    module Feed

      class Subscription < Base::Subscription

        def self.make(args)
          uri, path = *args
          raise Error, "No URI specified" unless uri
          uri = Addressable::URI.parse(uri)
          new(
            id: uri_to_id(uri, path: path),
            config: Config.new(uri: uri))
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
          @title = nil
          @items = []
          uris = @config.uri ? [@config.uri] : @config.uris
          raise Error, "No URI(s) defined for #{@id}" if uris.empty?
          uris.each do |uri|
            if (feedjira = get_feedjira(uri))
              @title ||= feedjira.title
              @items += feedjira.entries.map { |e| Item.new(e) }
            end
          end
        end

        def get_feedjira(uri)
          resource = Resource.get(uri)
          if resource.moved && !@config.ignore_moved
            $logger.warn { "#{@id}: URI #{resource.uri} moved to #{resource.redirected_uri}" }
          end
          Feedjira.configure { |c| c.strip_whitespace = true }
          begin
            Feedjira.parse(resource.content.force_encoding(Encoding::UTF_8))
          rescue StandardError, Feedjira::NoParserAvailable, Date::Error => e
            raise Error, "Can't parse XML feed from #{resource.uri}: #{e}"
          end
        end

        def process
          @items.reject! do |item|
            if @config.ignore_uris
              regexps = [@config.ignore_uris].flatten.map { |r| Regexp.new(r) }
              if regexps.find { |r| item.uri.to_s =~ r }
                $logger.debug { "#{@id}: removing ignored item #{item.id}" }
                true
              end
            end
          end
        end

      end

      class Item < Base::Item

        attr_accessor :content

        def initialize(entry)
          if entry.url
            begin
              uri = Addressable::URI.parse(entry.url.strip)
            rescue Addressable::URI::InvalidURIError => e
              raise Error, "Can't parse URL for entry: #{entry.url.inspect}"
            end
          else
            uri = nil
          end
          id = entry.entry_id || uri or raise Error, "Can't determine ID or URL for entry"
          super(
            id: id.to_s,
            uri: uri,
            date: entry.published || Time.now,
            title: entry.title,
            author: entry.respond_to?(:author) ? entry.author&.sub(/^by\s+/i, '') : nil,
            content: (entry.content || entry.summary)&.to_s,
          )
        end

        def to_html
          Simple::Builder.build_html do |html|
            if @title
              html.h1 do
                html << @title.to_html
              end
            end
            html.h2 do
              html << [date_str, @author].compact.join(' • ').to_html
            end
            if @uri
              html.h3 do
                html.a(@uri.prettify, href: @uri)
              end
            end
            if @content
              html << (@content.html? ? scrub_html(@content) : text_to_html(@content))
            end
          end
        end

      end

    end

  end

end