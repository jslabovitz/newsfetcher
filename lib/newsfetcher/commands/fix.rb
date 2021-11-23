module NewsFetcher

  module Commands

    class Fix < Command

      def run(args)
        super
        @profile.fix(args)
      end

    end

  end

end