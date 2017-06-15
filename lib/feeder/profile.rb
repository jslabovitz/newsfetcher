module Feeder

  class Profile

    def initialize(plist_file=nil)
      @plist_file ||= Feeder.subscriptions_file
    end

    def list
      each_subscription { |s| p(s) }
    end

    def update
      each_subscription { |s| s.update }
    end

    def process
      feeds = each_subscription.map { |s| s.process }
      Feeder.save_json(feeds, Feeder.compilation_file)
    end

    def each_subscription(&block)
      return to_enum(__method__) unless block_given?
      IO.popen(['plutil', '-convert', 'xml1', '-o', '-', @plist_file.to_s], 'r') do |io|
        plist = Nokogiri::PList(io)
        recurse_plist(plist) do |subscription_plist, path|
          yield Subscription.new(
            id: subscription_plist['id'],
            title: subscription_plist['name'],
            feed_link: subscription_plist['rss'],
            path: path)
        end
      end
    end

    private

    def recurse_plist(items, path=[], &block)
      items.each do |item|
        if item['isContainer']
          recurse_plist(item['childrenArray'], path + [item['name']], &block)
        else
          yield(item, path)
        end
      end
    end

  end

end