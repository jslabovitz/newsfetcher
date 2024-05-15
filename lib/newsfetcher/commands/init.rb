module NewsFetcher

  module Commands

    class Init < Command

      attr_accessor :mail_from
      attr_accessor :mail_to

      def run(args)
        super
        raise Error, "Must specify mail_from" unless @mail_from
        raise Error, "Must specify mail_to" unless @mail_to
        @profile = Profile.new(
          dir: @dir,
          config: BaseConfig.make(
            mail_from: @mail_from,
            mail_to: @mail_to,
          ),
        )
        profile.save
      end

    end

  end

end