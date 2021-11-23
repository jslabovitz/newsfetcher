module NewsFetcher

  module Commands

    class Edit < Command

      def run(args)
        super
        @profile.edit(args)
      end

    end

  end

end