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

    def each_feed(args, &block)
      feed_dirs(args).each do |feed_dir|
        feed = Feed.load(dir: feed_dir, profile: self)
        begin
          yield(feed)
        rescue Error => e
          raise Error, "#{feed.id}: #{e}"
        end
      end
    end

    def feed_dirs(args)
      if args.empty?
        feeds_dir.glob("**/#{FeedInfoFileName}").map(&:dirname)
      else
        args.map do |arg|
          if arg =~ %r{^[/~]}
            Path.new(arg)
          else
            feeds_dir / arg
          end
        end
      end
    end

  end

end