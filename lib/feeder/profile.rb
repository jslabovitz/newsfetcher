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

    def select_feeds(args)
      if args.empty?
        dirs = feeds_dir.glob("**/#{FeedInfoFileName}").map(&:dirname)
      else
        dirs = args.map do |arg|
          if arg =~ %r{^[/~]}
            Path.new(arg)
          else
            feeds_dir / arg
          end
        end
      end
      dirs.map { |d| Feed.load(dir: d, profile: self) }
    end

  end

end