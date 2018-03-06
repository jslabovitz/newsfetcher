module Feeder

  class CommandProcessor

    def self.run(args)
      new(args).run
    end

    def initialize(args)
      @options = HashStruct.new(SimpleOptionParser.parse(args,
        subscriptions_file: Feeder.subscriptions_file))
      @subcommand = args.shift or raise "No subcommand specified"
      @args = args
    end

    def run
      @profile = Profile.new(@options.subscriptions_file)
      case @subcommand
      when 'list'
        @profile.list(@args)
      when 'update'
        @profile.update(@args)
      when 'process'
        @profile.process(@args)
      else
        raise
      end
    end

  end

end