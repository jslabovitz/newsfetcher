module Feeder

  class Profile

    def initialize(plist_file=nil)
      read_plist_file(plist_file || Feeder.subscriptions_file)
    end

    def list(ids=nil)
      subscriptions(:list, ids)
    end

    def update(ids=nil)
      subscriptions(:update, ids)
    end

    def process(ids=nil)
      subscriptions(:process, ids)
    end

    def subscriptions(method, ids=nil)
      subscriptions = ids ? ids.map { |id| @subscriptions[id] } : @subscriptions.values
      subscriptions.each do |subscription|
        begin
          subscription.send(method)
        rescue => e
          warn "Failed to #{method} #{subscription.title.inspect} (#{subscription.id}): #{e}"
        end
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