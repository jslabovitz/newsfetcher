module NewsFetcher

  module Commands

    class Reset < Command

      def run(args)
        super
        @profile.reset(args)
      end

    end

  end

end