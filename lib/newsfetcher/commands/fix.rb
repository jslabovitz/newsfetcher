module NewsFetcher

  module Commands

    class Fix < Command

      def run(args)
        profile_dir = Path.new('~/.newsfetcher').expand_path
        # fix profile
        config_file = profile_dir / ConfigFileName
;;puts config_file
        config = JSON.parse(config_file.read, symbolize_names: true)
        config[:delivery_method] = config.delete(:deliver_method)
        config[:delivery_params] = config.delete(:deliver_params)
        config[:delivery_params][:dir] = config[:delivery_params]&.delete(:location)
        if (folder = config[:delivery_params]&.delete(:folder))
          config[:root_folder] = folder
        end
        config_file.write(JSON.pretty_generate(config))
        # fix subscriptions
        profile_dir.glob('subscriptions/**/config.json').each do |config_file|
;;puts config_file
          config = JSON.parse(config_file.read, symbolize_names: true)
          if (disable = config.delete(:disable))
            config[:disabled] = disable
          end
          config.delete(:type)
          config_file.write(JSON.pretty_generate(config))
        end
      end

    end

  end

end