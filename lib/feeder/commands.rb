module Feeder

  class CommandProcessor

    def self.run(args)
      new.run(args)
    end

    def run(args)
      options = HashStruct.new(
        SimpleOptionParser.parse(args,
        profile: 'default')
      )
      subcommand = args.shift or raise Error, "No subcommand specified"
      args = args
      profile = Profile.new(name: options.delete(:profile))
      case subcommand
      when 'import'
        profile.import(args, options)
      when 'add'
        profile.add(args, options)
      when 'list'
        profile.list(args, options)
      when 'update'
        profile.update(args, options)
      else
        raise Error, "Unknown subcommand: #{subcommand.inspect}"
      end
    end

  end

end