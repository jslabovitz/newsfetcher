module NewsFetcher

  module Commands

    class Show < Command

      def run(args)
        super
        @profile.show(args,
          status: @status ? [@status.split(',').map(&:to_sym)] : nil,
          sort: @sort ? @sort.to_sym : nil,
          details: @details)
      end

    end

  end

end