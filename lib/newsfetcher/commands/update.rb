module NewsFetcher

  module Commands

    class Update < Command

      def run(args)
        super
        @profile.update(args)
      end

    end

  end

end