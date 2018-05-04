module NewsFetcher

  module Commands

    class Add < Command

      register_command 'add'

      def run(args)
        raise Error, "No profile specified" unless @profile
        uri = args.shift or raise Error, "No URI specified"
        path = args.shift
        @profile.subscribe(uri: uri, path: path)
      end

    end

  end

end