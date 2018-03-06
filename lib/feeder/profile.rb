module Feeder

  class Profile

    def initialize(plist_file)
      read_plist_file(plist_file)
    end

    def list(ids)
      subscriptions(:list, ids)
    end

    def update(ids)
      subscriptions(:update, ids)
    end

    def process(ids)
      subscriptions(:process, ids)
    end

    def subscriptions(method, ids)
      subscriptions = ids.empty? ? @subscriptions.values : ids.map { |id| @subscriptions[id] }
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