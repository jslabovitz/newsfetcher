module NewsFetcher

  class CLI

    def self.run(argv=ARGV)

      SimpleCommand.run(argv) do

        global do
          raise Error, "Must specify profile" unless @profile
          @profile = Profile.load(DataDir / @profile)
        end

        command 'dormant', period: 30 do |args|
          @profile.dormancy_report(args, period: @period).each do |subscription_id, days|
            puts "\t%5s: %s" % [
              days ? days.to_i : 'never',
              subscription_id,
            ]
          end
        end

        command 'fix' do |subscription_ids|
          @profile.subscriptions(subscription_ids).each do |subscription|
            subscription.fix
          end
        end

        command 'import' do |plist_file|
          plist_file = args.shift or raise Error, "Must specify plist file"
          @profile.import(plist_file)
        end

        command 'process', ignore_history: false, limit: nil do |subscription_ids|
          @profile.subscriptions(subscription_ids).each do |subscription|
            begin
              subscription.process(ignore_history: @ignore_history, limit: @limit)
            rescue Error => e
              warn "#{subscription.id}: #{e}"
            end
          end
        end

        command 'subscribe' do |uri, path|
          raise Error, "No URI specified" unless uri
          @profile.subscribe(uri: uri, path: path)
        end

        command 'update', max_threads: nil do |subscription_ids|
          @profile.update_subscriptions(subscription_ids, max_threads: @max_threads)
        end

      end

    end

  end

end