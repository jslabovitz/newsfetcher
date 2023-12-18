module NewsFetcher

  module Commands

    class Edit < Command

      def run(args)
        super
        editor = ENV['EDITOR'] or raise Error, "No editor defined in $EDITOR"
        @profile.find_subscriptions(ids: args).each do |subscription|
          system(editor, (subscription.dir / ConfigFileName).to_s)
        end
      end

    end

  end

end