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
          json = html.at_xpath('//script[@id="__NEXT_DATA__"]')
          data = JSON.load(json)
          begin
            jobs = data['props']['pageProps']['jobs']
            case jobs
            when Array
              @items += jobs.map { |j| Item.new(j) }
            when { 'msg' => 'No jobs found.' }
              # ignore
            else
              raise Error, "Unexpected result: #{jobs.inspect}"
            end
          rescue => e
            ;;pp data
            raise e
          end
        end

      end

      class Item < Base::Item

        attr_accessor :images

        AttrMap = {
          'id' => :id,
          'enqueue_time' => proc { |v|
            { date: DateTime.parse(v).to_time }
          },
          'prompt' => :title,
          'username' => :author,
          'image_paths' => proc { |v|
            { images: v.map { |s| Addressable::URI.parse(s) } }
          },
        }

        def initialize(job)
          super()
          AttrMap.each do |str, info|
            value = job[str] or raise Error, "Missing job info for key #{str.inspect}"
            hash = case info
            when nil
              { str.to_sym => value }
            when Symbol
              { info => value }
            when Proc
              info.call(value)
            else
              raise
            end
            set(hash)
          end
        end

        def to_html
          Simple::Builder.build_html do |html|
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