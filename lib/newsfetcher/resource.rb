module NewsFetcher

  class Resource

    attr_accessor :uri
    attr_accessor :redirected_uri
    attr_accessor :content

    def self.get(params)
      new(*params).tap(&:get)
    end

    def initialize(uri, connection: nil)
      @uri = uri
      @redirected_uri = nil
      @connection = connection
      @redirects = 0
    end

    def get
      @current_uri = @redirected_uri || @uri
      @content = nil
      response = silence_warnings do
        connection = Faraday.new(
          url: @current_uri,
          request: { timeout: DownloadTimeout },
          ssl: { verify: false })
        begin
          connection.get
        rescue Faraday::ConnectionFailed, Zlib::BufError, StandardError => e
          raise Error, "Network error: #{e.message} (#{e.class})"
        end
      end
      case response.status
      when 200...300
        @content = response.body
      when 300...400
        @redirected_uri = @current_uri.join(Addressable::URI.parse(response.headers[:location]))
        if response.status == 302
          $logger.warn { "#{@current_uri}: Permanently moved to #{@redirected_uri}" }
        end
        raise Error, "Too many redirects" if @redirects == DownloadFollowRedirectLimit
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