module Addressable

  class URI

    def prettify
      uri = dup
      if uri.query
        uri.query_values = uri.query_values.tap do |query|
          query.delete_if { |k, v| k =~ /^utm_/ || k == 'icid' }
        end
        uri.query = nil if uri.query_values.empty?
      end
      case uri.scheme
      when 'http', 'https'
        uri.host = uri.host.sub(/^www\./, '')
        uri.to_s.sub(%r{^https?://}, '')
      when 'mailto'
        uri.path.to_s
      else
        uri.to_s
      end
    end

  end

end