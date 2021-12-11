module NewsFetcher

  class Result

    attr_accessor :location
    attr_accessor :reason
    attr_accessor :status
    attr_accessor :headers
    attr_accessor :content
    attr_accessor :subscription
    attr_accessor :title
    attr_accessor :items

    include SetParams

    def self.load(file, subscription:)
      raise Error, "No result file" unless file.exist?
      result = new(JSON.parse(file.read))
      result.parse_feed
      result.items.each { |i| i.subscription = subscription }
      result
    end

    def self.get(uri, headers: nil, subscription:)
      redirects = 0
      loop do
        response = silence_warnings do
          connection = Faraday.new(
            url: uri,
            headers: headers || {},
            request: { timeout: DownloadTimeout },
            ssl: { verify: false })
          begin
            connection.get
          rescue Faraday::ConnectionFailed, Zlib::BufError, StandardError => e
            return Result.new(type: :network_error, reason: "#{e.message} (#{e.class})")
          end
        end
        case (result_type = http_status_result_type(response.status))
        when :moved
          return new(type: result_type, reason: "Permanently moved to #{response.headers[:location]}")
        when :redirection
          redirects += 1
          if redirects > DownloadFollowRedirectLimit
            return new(type: :redirect_error, reason: 'Too many redirects')
          end
          uri = uri.join(Addressable::URI.parse(response.headers[:location]))
        else
          result = new(
            status: response.status,
            reason: response.reason_phrase,
            headers: response.headers,
            content: response.body.force_encoding(Encoding::UTF_8),
            subscription: subscription)
          result.parse_feed
          return result
        end
      end
    end

    def self.http_status_result_type(code)
      case code
      when 100...200
        :informational
      when 200...300
        :successful
      when 302
        :moved
      when 304
        :not_modified
      when 300...400
        :redirection
      when 400...500
        :client_error
      when 500...600
        :server_error
      else
        :unknown_status
      end
    end

    def location=(location)
      # ignored (FIXME: remove from result files)
    end

    def type=(type)
      #FIXME: ignored
    end

    def type
      self.class.http_status_result_type(@status)
    end

    def items_hash
      @items&.map { |i| [i.id, i] }.to_h || {}
    end

    def to_hash
      {
        reason: @reason,
        status: @status,
        headers: @headers,
        content: @content,
      }
    end

    def save(file)
      file.write(JSON.pretty_generate(to_hash))
    end

    def parse_feed
      case @content
      when /^</
        parse_xml_feed
      when /^\{/
        parse_json_feed
      else
        raise Error, "Unknown content type for feed: #{(@content[0..9] + '...').inspect}"
      end
    end

    def parse_xml_feed
      begin
        Feedjira.configure { |c| c.strip_whitespace = true }
        feed = Feedjira.parse(@content)
      rescue => e
        raise Error, "Can't parse XML feed: #{e}"
      end
      @title = feed.title
      @items = feed.entries.map do |entry|
        Item.new(
          subscription: @subscription,
          id: entry.entry_id || entry.url,
          date: entry.published || Time.now,
          title: entry.title,
          url: entry.url,
          author: entry.respond_to?(:author) ? entry.author : nil,
          content: entry.content || entry.summary || '')
      end
    end

    def parse_json_feed
      begin
        feed = JSON.parse(@content)
      rescue => e
        raise Error, "Can't parse JSON feed: #{e}"
      end
      @title = feed['title']
      @items = feed['items'].map do |item|
        Item.new(
          subscription: @subscription,
          id: item['id'] || item['url'],
          date: item['date_published'] || Time.now,
          title: item['title'],
          url: item['url'],
          author: item['author'] && item['author']['name'],
          content: item['content_html'] || item['summary'])
      end
    end

    def print
      puts '%s %p (%s %s) [%s]' % [
        @location,
        @title,
        @status,
        @reason,
        @subscription&.title,
      ]
      if @items
        @items.each do |item|
          puts item.to_info
        end
      end
    end

  end

end