module NewsFetcher

  module Commands

    class Init < Command

      def run(args)
        super
        raise Error, "Must specify mail_from" unless @mail_from
        raise Error, "Must specify mail_to" unless @mail_to
        Profile.init(@dir, mail_from: @mail_from, mail_to: @mail_to)
      end

    end

  end

end