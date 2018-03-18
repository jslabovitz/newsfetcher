module Feeder

  class Profile

    attr_accessor :root_dir
    attr_accessor :feeds_dir
    attr_accessor :email
    attr_accessor :maildir

    def self.load(dir)
      info_file = dir / 'info.yaml'
      new(YAML.load(info_file.read).merge(root_dir: dir))
    end

    def initialize(params={})
      params.each { |k, v| send("#{k}=", v) }
    end

    def to_yaml
      {
        email: @email,
        maildir: @maildir,
      }.to_yaml(line_width: -1)
    end

    def feeds_dir
      @root_dir / 'feeds'
    end

    def style
      @style ||= Feeder::StylesheetFile.read
    end

    def info_files(args)
      if args.empty?
        feeds_dir.glob("**/*.yaml")
      else
        args.map do |arg|
          if arg =~ /\.yaml$/
            Path.new(arg)
          else
            (feeds_dir / arg).add_extension('.yaml')
          end
        end
      end
    end

    def each_feed(args, &block)
      info_files(args).each do |info_file|
        feed = Feed.load(info_file: info_file, profile: self)
        begin
          yield(feed)
        rescue Error => e
          raise Error, "#{feed.id}: #{e}"
        end
      end
    end

  end

end