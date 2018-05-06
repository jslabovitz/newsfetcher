module NewsFetcher

  module Commands

    class Import < Command

      register_command 'import'

      def run(args)
        plist_file = args.shift or raise Error, "Must specify plist file"
        @profile.import(plist_file)
      end

    end

  end

end