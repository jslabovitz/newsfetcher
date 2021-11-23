module NewsFetcher

  module Commands

    class Prune < Command

      def run(args)
        super
        @profile.prune(args,
          before: @before && @before.to_time,
          after: @after && @after.to_time)
      end

    end

  end

end