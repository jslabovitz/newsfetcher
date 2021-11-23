module NewsFetcher

  module Commands

    class ImportYoutube < Command

      def run(args)
        super
        @profile.import_youtube(args)
      end

    end

  end

end