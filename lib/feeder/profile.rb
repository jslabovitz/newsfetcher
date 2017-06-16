module Feeder

  class Profile

    def initialize(plist_file=nil)
      read_plist_file(plist_file || Feeder.subscriptions_file)
    end

    def list(ids=nil)
      subscriptions(ids).each { |s| p(s) }
    end

    def update(ids=nil)
      subscriptions(ids).each { |s| s.update }
    end

    def process(ids=nil)
      subscriptions(ids).each { |s| s.process }
    end

    def subscriptions(ids=nil)
      if ids
        ids.map { |id| @subscriptions[id] }
      else
        @subscriptions.values
      end
    end

    private

    def read_plist_file(file)
      @subscriptions = {}
      io = IO.popen(['plutil', '-convert', 'xml1', '-o', '-', file.to_s], 'r')
      plist = Nokogiri::PList(io)
      recurse_plist(plist)
    end

    def recurse_plist(items, path=[])
      items.each do |item|
        if item['isContainer']
          recurse_plist(item['childrenArray'], path + [item['name']])
        else
          id = item['id']
          @subscriptions[id] = Subscription.new(
            id: id,
            title: item['name'],
            feed_link: item['rss'],
            path: path)
        end
      end
    end

  end

end