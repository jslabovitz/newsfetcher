module Feeder

  module Commands

    class Import < Command

      register_command 'import'

      def run(args)
        plist_file = args.shift or raise Error, "Must specify plist file"
        import_plist(plist_file)
      end

    end

  end

end