module NewsFetcher

  module Commands

    class Export < Command

      def run(args)
        super
        @profile.export(args)
      end

    end

  end

end