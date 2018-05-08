module NewsFetcher

  module Commands

    class Subscribe < Command

      register_command 'subscribe'

      def run(args)
        raise Error, "Must specify one profile" unless @profiles.length == 1
        uri = args.shift or raise Error, "No URI specified"
        path = args.shift
        @profiles.first.subscribe(uri: uri, path: path)
      end

    end

  end

end