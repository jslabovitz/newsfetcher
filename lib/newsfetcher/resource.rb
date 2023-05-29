module NewsFetcher

  class Resource

    attr_accessor :uri
    attr_accessor :redirected_uri
    attr_accessor :content
    attr_accessor :timeout
    attr_accessor :max_redirects
    attr_accessor :redirects
    attr_accessor :moved

    include SetParams

    def self.get(uri, **params)
      new(uri, **params).tap(&:get)
    end

    def initialize(uri, params={})
      @uri = Addressable::URI.parse(uri.to_s)
      @redirected_uri = nil
      @timeout = 30
      @max_redirects = 5
      @max_tries = 3
      @redirects = 0
      @moved = false
      set(params)
    end

    def get
      @current_uri = @redirected_uri || @uri
      @tries = 0
      @content = nil
      response = silence_warnings do
        connection = Faraday.new(
          url: @current_uri,
          request: { timeout: @timeout },
          ssl: { verify: false })
        begin
          connection.get
        rescue Faraday::ConnectionFailed => e
          if @tries < @max_tries
            @tries += 1
            retry
          else
            raise Error, "Connection error: #{e.message} (#{e.class})"
          end
        rescue Zlib::BufError, StandardError => e
          raise Error, "Error: #{e.message} (#{e.class})"
        end
      end
      case response.status
      when 200...300
        @content = response.body
      when 300...400
        location = response.headers[:location] or raise Error, "No Location header found in redirect"
        @redirected_uri = @current_uri.join(Addressable::URI.parse(location))
        @moved = (response.status == 302)
        raise Error, "Too many redirects" if @redirects == @max_redirects
        @redirects += 1
        get
      when 400...600
        raise Error, "HTTP error: #{response.reason_phrase} (#{response.status})"
      else
        raise Error, "Unexpected HTTP response: #{response.reason_phrase} (#{response.status})"
      end
    end

  end

end