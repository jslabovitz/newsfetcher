module NewsFetcher

  module Commands

    class Import < Command

      register_command 'import'

      def run(args)
        raise Error, "Must specify one profile" unless @profiles.length == 1
        plist_file = args.shift or raise Error, "Must specify plist file"
        @profile.import(plist_file)
      end

    end

  end

end