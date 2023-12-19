module NewsFetcher

  class Fetcher

    attr_reader   :uri
    attr_accessor :timeout
    attr_accessor :max_redirects
    attr_accessor :moved
    attr_accessor :actual_uri

    include SetParams

    def self.get(uri)
      new(uri: uri).tap(&:get)
    end

    def initialize(**params)
      super({
        timeout: 30,
        max_redirects: 5,
      }.merge(params))
    end

    def uri=(uri)
      @uri = Addressable::URI.parse(uri)
    end

    def success?
      @response.success?
    end

    def response_status
      @response&.status
    end

    def response_reason
      @response&.reason_phrase
    end

    def content
      @response&.body
    end

    def parse_feed
      raise Error, "No response yet" unless @response
      raise Error, "Can't parse feed in failed response" unless @response.success?
      Feedjira.configure { |c| c.strip_whitespace = true }
      begin
        feedjira = Feedjira.parse(content)
      rescue Feedjira::NoParserAvailable, Date::Error => e
        raise Error, "Can't parse XML feed from #{@uri}: #{e}"
      end
      {
        title: feedjira.title,
        items: feedjira.entries.map { |e| Item.new(e) },
      }
    end

    def find_feeds
      raise Error, "No response yet" unless @response
      raise Error, "Can't find feeds in failed response" unless @response.success?
      html = Nokogiri::HTML::Document.parse(content)
      html.xpath('//link[@rel="alternate"]').select { |link| FeedTypes.include?(link['type']) }.map do |link|
        {
          uri: @uri.join(link['href']),
          type: link['type'],
        }
      end
    end

    def get
      @actual_uri = @uri
      redirects = 0
      while redirects < @max_redirects do
        @response = nil
        connection = Faraday.new(
          url: @actual_uri,
          request: { timeout: @timeout },
          ssl: { verify: false })
        begin
          @response = connection.get
        rescue Faraday::Error => e
          raise Error, "Error: #{e.message} (#{e.class})"
        end
        if (300...400).include?(@response.status)
          @moved = (@response.status == 302)
          location = @response.headers[:location] or raise Error, "No Location header found in redirect"
          @actual_uri = @actual_uri.join(Addressable::URI.parse(location))
          redirects += 1
          next
        end
        return @response.success?
      end
      raise Error, "Too many redirects"
    end

  end

end