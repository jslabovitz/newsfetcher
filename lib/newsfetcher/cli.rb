module NewsFetcher

  class CLI

    def self.run(argv=ARGV)

      SimpleCommand.run(argv) do

        global dir: DefaultProfileDir do
          @profile = Profile.load(@dir)
        end

        command 'dormant', period: 30 do |args|
          @profile.dormancy_report(args, period: @period).each do |subscription_id, days|
            puts "\t%5s: %s" % [
              days ? days.to_i : 'never',
              subscription_id,
            ]
          end
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

        command 'subscribe' do |uri, path|
          raise Error, "No URI specified" unless uri
          @profile.subscribe(uri: uri, path: path)
        end

        command 'update-feeds', max_threads: nil do |subscription_ids|
          @profile.update_subscriptions(subscription_ids, max_threads: @max_threads)
        end

      end

    end

  end

end