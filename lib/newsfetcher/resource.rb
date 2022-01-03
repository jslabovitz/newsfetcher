module NewsFetcher

  class Resource

    attr_accessor :uri
    attr_accessor :redirected_uri
    attr_accessor :content

    def self.get(uri)
      new(uri).tap(&:get)
    end

    def initialize(uri)
      @uri = uri
    end

    def get(redirects: 0)
      current_uri = @redirected_uri || @uri
      response = silence_warnings do
        connection = Faraday.new(
          url: current_uri,
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
        @redirected_uri = current_uri.join(Addressable::URI.parse(response.headers[:location]))
        if response.status == 302
          $logger.warn { "#{@uri}: Permanently moved to #{@redirected_uri}" }
        end
        raise Error, "Too many redirects" if redirects == DownloadFollowRedirectLimit
        get(redirects: redirects + 1)
      when 400...600
        raise Error, "HTTP error: #{response.reason_phrase} (#{response.status})"
      else
        raise Error, "Unexpected HTTP response: #{response.reason_phrase} (#{response.status})"
      end
    end

    def redirected?
      @redirected_uri != nil
    end

  end

end