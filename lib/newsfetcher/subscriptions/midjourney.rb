module NewsFetcher

  module Subscriptions

    module Midjourney

      class Subscription < Base::Subscription

        def self.make(args)
          uri, path = *args
          raise Error, "No URI specified" unless uri
          uri = Addressable::URI.parse(uri)
          new(
            id: uri_to_id(uri, path: path),
            config: Config.new(uri: uri))
        end

        def get
          @title ||= 'Midjourney'
          @items = []
          resource = Resource.get(@config.uri)
          html = Nokogiri::HTML(resource.content)
# ;;puts html
          json = html.at_xpath('//script[@id="__NEXT_DATA__"]')
# ;;pp json
          data = JSON.load(json)
# ;;pp data
          jobs = data['props']['pageProps']['jobs']
          @items += jobs.map { |j| Item.new(j) }
        end

      end

      class Item < Base::Item

        attr_accessor :prompt
        attr_accessor :images

        def initialize(job)
          super(
            id: job['id'],
            date: DateTime.parse(job['enqueue_time']).to_time,
            title: job['prompt'],
            author: job['username'],
            prompt: job['prompt'],
            images: job['image_paths'].map { |s| Addressable::URI.parse(s) },
          )
        end

        def to_html
          Simple::Builder.html_fragment do |html|
            @images.each do |image|
              html.p do
                html.a(href: image) do
                  html.img(src: image)
                end
              end
            end
            html.h1 do
              html << @title.to_html
            end
            html.h2 do
              html << [date_str, @author].compact.join(' • ').to_html
            end
          end
        end

      end

    end

  end

end