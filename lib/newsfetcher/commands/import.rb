module NewsFetcher

  module Commands

    class Import < Command

      def run(args)
        super
        @profile.import(args)
      end

    end

  end

end