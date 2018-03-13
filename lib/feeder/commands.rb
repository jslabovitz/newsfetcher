module Feeder

  class CommandProcessor

    def self.run(args)
      new.run(args)
    end

    def run(args)
      options = HashStruct.new(SimpleOptionParser.parse(args))
      subcommand = args.shift or raise Error, "No subcommand specified"
      profile_name = options.delete(:profile) or raise Error, "No profile specified"
      profile_dir = Path.new(DefaultDataDir, profile_name).expand_path
      profile = Profile.load(profile_dir)
      case subcommand
      when 'import'
        profile.import(args, options)
      when 'add'
        profile.add(args, options)
      when 'update'
        profile.update(args, options)
      when 'fix'
        profile.fix(args, options)
      else
        raise Error, "Unknown subcommand: #{subcommand.inspect}"
      end
    end

  end

end