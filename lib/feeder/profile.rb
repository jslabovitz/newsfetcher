module Feeder

  class Profile

    attr_accessor :subscriptions

    def initialize(plist_file=nil)
      @subscriptions = read_plist_file(plist_file || Feeder.subscriptions_file)
    end

    def list
      @subscriptions.each { |s| p(s) }
    end

    def update
      @subscriptions.each { |s| s.update }
    end

    def process
      @subscriptions.each { |s| s.process }
    end

    def read_plist_file(file)
      io = IO.popen(['plutil', '-convert', 'xml1', '-o', '-', file.to_s], 'r')
      plist = Nokogiri::PList(io)
      recurse_plist(plist)
    end

    private

    def recurse_plist(items, path=[])
      items.map do |item|
        if item['isContainer']
          recurse_plist(item['childrenArray'], path + [item['name']])
        else
          Subscription.new(
            id: item['id'],
            title: item['name'],
            feed_link: item['rss'],
            path: path)
        end
      end.flatten
    end

  end

end