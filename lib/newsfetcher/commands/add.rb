module NewsFetcher

  module Commands

    class Add < Command

      def run(args)
        super
        uri, path = *args
        raise Error, "No URI specified" unless uri
        @profile.add_subscription(uri: uri, path: path)
      end

    end

  end

end