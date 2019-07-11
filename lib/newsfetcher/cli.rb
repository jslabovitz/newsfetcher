module NewsFetcher

  class CLI

    def self.run(argv=ARGV)

      SimpleCommand.run(argv) do

        global dir: DefaultProfileDir, log_level: nil do
          @dir = Path.new(@dir)
          if @dir.exist?
            @profile = Profile.new(dir: @dir, log_level: @log_level && @log_level.to_sym)
          end
        end

        command 'init', mail_from: nil, mail_to: nil do |args|
          raise Error, "Must specify mail_from" unless @mail_from
          raise Error, "Must specify mail_to" unless @mail_to
          Profile.init(@dir, mail_from: @mail_from, mail_to: @mail_to)
        end

        command 'list', status: nil, sort: nil do |args|
          raise Error, "Profile not loaded" unless @profile
          @profile.list(args,
            status: @status ? [@status.split(',').map(&:to_sym)] : nil,
            sort: @sort ? @sort.to_sym : nil)
        end

        command 'discover' do |args|
          raise Error, "Profile not loaded" unless @profile
          args.each do |uri|
            @profile.discover_feed(uri)
          end
        end

        command 'fix' do |subscription_ids|
          raise Error, "Profile not loaded" unless @profile
          @profile.fix(subscription_ids)
        end

        command 'update' do |subscription_ids|
          raise Error, "Profile not loaded" unless @profile
          @profile.update(subscription_ids)
        end

        command 'add' do |uri, path|
          raise Error, "No URI specified" unless uri
          @profile.add_subscription(uri: uri, path: path)
        end

        command 'remove' do |subscription_ids|
          raise Error, "Profile not loaded" unless @profile
          @profile.remove(subscription_ids)
        end

        command 'reset' do |subscription_ids|
          raise Error, "Profile not loaded" unless @profile
          @profile.reset(subscription_ids)
        end

        command 'show', keys: nil do |subscription_ids|
          raise Error, "Profile not loaded" unless @profile
          @keys = @keys.split(',').map(&:to_sym) if @keys
          @profile.show(subscription_ids, keys: @keys)
        end

        command 'show-message' do |subscription_ids|
          raise Error, "Profile not loaded" unless @profile
          @profile.show_message(subscription_ids)
        end

      end

    end

  end

end