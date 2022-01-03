module NewsFetcher

  module Commands

    class Add < Command

      def run(args)
        super
        uri, path = *args
        raise Error, "No URI specified" unless uri
        uri = Addressable::URI.parse(uri)
        id = Subscription.uri_to_id(uri, path: path)
        @profile.add_subscription(uri: uri, id: id)
      end

    end

  end

end