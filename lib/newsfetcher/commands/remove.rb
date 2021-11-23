module NewsFetcher

  module Commands

    class Remove < Command

      def run(args)
        super
        @profile.remove(args)
      end

    end

  end

end