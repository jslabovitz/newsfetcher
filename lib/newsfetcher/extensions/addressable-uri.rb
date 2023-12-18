module Addressable

  class URI

    def make_subscription_id
      [
        host.to_s \
          .sub(/^(www|ssl|en|feeds|rss|blogs?|news).*?\./i, '') \
          .sub(/\.(com|org|net|info|edu|co\.uk|wordpress\.com|blogspot\.com|feedburner\.com)$/i, ''),
        path.to_s \
          .gsub(/\b(\.?feeds?|index|atom|rss|rss2|xml|rdf|php|blog|posts|default)\b/i, ''),
        query.to_s \
          .gsub(/\b(format|feed|type|q)=(atom|rss\.xml|rss2?|xml)/i, ''),
      ] \
        .join(' ')
        .downcase
        .gsub(/[^a-z0-9]+/, ' ')  # non-alphanumeric
        .strip
        .gsub(/\s+/, '-')
    end

  end

end