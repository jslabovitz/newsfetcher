module NewsFetcher

  class CLI

    def self.run(argv=ARGV)

      SimpleCommand.run(argv) do

        global dir: DefaultProfileDir do
          @profile = Profile.load(@dir)
        end

        command 'list', status: nil, sort: nil do |args|
          @profile.list(args,
            status: @status ? [@status.split(',').map(&:to_sym)] : nil,
            sort: @sort.to_sym)
        end

        command 'discover' do |args|
          args.each do |uri|
            @profile.discover_feed(uri)
          end
        end

        command 'fix' do |subscription_ids|
          @profile.fix_subscriptions(subscription_ids)
        end

        command 'update', max_threads: nil, ignore_history: false, limit: nil do |subscription_ids|
          @profile.update(subscription_ids,
            max_threads: @max_threads,
            ignore_history: @ignore_history,
            limit: @limit)
        end

        command 'process', ignore_history: false, limit: nil do |subscription_ids|
          @profile.process_subscriptions(subscription_ids, ignore_history: @ignore_history, limit: @limit)
        end

        command 'add' do |uri, path|
          raise Error, "No URI specified" unless uri
          @profile.add_subscription(uri: uri, path: path)
        end

        command 'remove' do |subscription_ids|
          @profile.remove_subscriptions(subscription_ids)
        end

        command 'reset' do |subscription_ids|
          @profile.reset_subscriptions(subscription_ids)
        end

        command 'update-feeds', max_threads: nil do |subscription_ids|
          @profile.update_subscriptions(subscription_ids, max_threads: @max_threads)
        end

      end

    end

  end

end