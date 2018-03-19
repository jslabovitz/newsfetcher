module Feeder

  module Commands

    class Add < Command

      register_command 'add'

      def run(args)
        raise Error, "No profile specified" unless @profile
        uri = args.shift or raise Error, "No feed URI specified"
        path = args.shift
        @profile.add_feed(uri: uri, path: path)
      end

    end

  end

end