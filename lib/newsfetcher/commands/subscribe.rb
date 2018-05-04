module NewsFetcher

  module Commands

    class Subscribe < Command

      register_command 'subscribe'

      def run(args)
        raise Error, "No profile specified" unless @profile
        uri = args.shift or raise Error, "No URI specified"
        path = args.shift
        @profile.subscribe(uri: uri, path: path)
      end

    end

  end

end