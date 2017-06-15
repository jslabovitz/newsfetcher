module Feeder

  class CommandProcessor

    def self.run(args)
      new(args).run
    end

    def initialize(args)
      parse_arguments(args)
    end

    def parse_arguments(args)
      @options = HashStruct.new
      while args.first =~ /^--(\w+)=(.*)$/
        @options[$1.to_sym] = $2
        args.shift
      end
      @command = args.shift
      @args = args
      @profile = Profile.new
    end

    def run
      case @command
      when 'list'
        @profile.list
      when 'update'
        @profile.update
      when 'process'
        @profile.process
      else
        raise
      end
    end

  end

end