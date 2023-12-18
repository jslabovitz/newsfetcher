module NewsFetcher

  module Commands

    class Add < Command

      def run(args)
        super
        uri, path, id = *args
        raise Error, "No URI specified" unless uri
        dir = @profile.add_subscription(uri: uri, id: id, path: path)
        warn "Added subscription: #{dir}"
      end

    end

  end

end