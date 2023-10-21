module NewsFetcher

  module Commands

    class Add < Command

      def run(args)
        super
        uri, path, id = *args
        raise Error, "No URI specified" unless uri
        uri = Addressable::URI.parse(uri)
        subscription = @profile.add_subscription(uri: uri, id: id, path: path)
        warn "Added subscription: #{subscription.id}"
      end

    end

  end

end