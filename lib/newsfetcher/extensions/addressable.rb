module Addressable

  class URI

    def prettify
      case scheme
      when 'http', 'https'
        host.sub(/^www\./, '') + path.sub(%r{(\.html?|/)$}, '')
      when 'mailto'
        path.to_s
      else
        to_s
      end
    end

  end

end