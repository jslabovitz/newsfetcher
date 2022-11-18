module NewsFetcher

  module Subscriptions

    module Base

      class Subscription

        attr_accessor :id
        attr_accessor :dir
        attr_accessor :config
        attr_accessor :styles
        attr_accessor :items
        attr_accessor :title

        include SetParams
        include Simple::Printer::Printable

        def self.type
          to_s.split('::')[-2].downcase
        end

        def initialize(params={})
          @title = nil
          @items = []
          set(params)
          load_history
        end

        def inspect
          to_s
        end

        def type
          self.class.type
        end

        def printable
          [
            [:id, 'ID'],
            [:uri, 'URI', config.uri],
            :dir,
            :type,
            :title,
            :status,
            [:age, 'Age', (a = age) ? '%d days' % (a / 60 / 60 / 24) : 'never'],
            :items,
          ]
        end

        def config_file
          raise Error, "dir not set" unless @dir
          @dir / ConfigFileName
        end

        def history_file
          raise Error, "dir not set" unless @dir
          @dir / HistoryFileName
        end

        def exist?
          raise Error, "dir not set" unless @dir
          @dir.exist?
        end

        def save
          raise Error, "dir not set" unless @dir
          @dir.mkpath unless @dir.exist?
          @config.save(config_file)
        end

        def age
          latest_key, latest_time = @history.latest_entry
          if latest_time
            Time.now - latest_time
          else
            nil
          end
        end

        def status
          if (a = age)
            if a > @config.max_age
              :dormant
            else
              :active
            end
          else
            :new
          end
        end

        def load_history
          if @dir && history_file.exist?
            @history = History.load(history_file)
            @history.prune(before: Time.now - @config.max_age) do |id, time|
              $logger.info { "pruning #{id.inspect} (#{time})"}
            end
            @history.save(history_file)
          else
            @history = History.new
          end
        end

        def update
          $logger.debug { "#{@id}: updating" }
          begin
            get
            remove_outdated
            process
            deliver
          rescue Error => e
            $logger.error { "#{@id}: #{e}" }
          end
        end

        def get
          # implemented in subclass
        end

        def remove_outdated
          @items.reject! do |item|
            if @history.include?(item.id) || item.age > @config.max_age
              true
            else
              @history[item.id] = item.date
              false
            end
          end
          @history.save(history_file)
        end

        def process
          # implemented in subclass
        end

        def deliver
          @items.sort_by(&:date).each do |item|
            send_mail(make_mail(item))
          end
        end

        def reset
          @history.reset(history_file)
        end

        def remove
          raise Error, "dir not set" unless @dir
          @dir.rmtree
        end

        def fix
        end

        def edit
          system(
            ENV['EDITOR'] || 'vi',
            config_file.to_s)
        end

        def make_mail(item)
          mail_from    = @config.mail_from or raise Error, "mail_from not specified in config"
          mail_to      = @config.mail_to or raise Error, "mail_to not specified in config"
          mail_subject = @config.mail_subject or raise Error, "mail_subject not specified in config"
          fields = {
            subscription_id: @id,
            item_title: item.title,
          }
          mail = Mail.new
          mail.date =         item.date
          mail.from =         ERB.new(mail_from).result_with_hash(fields)
          mail.to =           ERB.new(mail_to).result_with_hash(fields)
          mail.subject =      ERB.new(mail_subject).result_with_hash(fields)
          mail.content_type = 'text/html'
          mail.charset =      'utf-8'
          mail.body =         render_item(item)
          mail
        end

        def send_mail(mail)
          deliver_method, deliver_params =
            @config.deliver_method&.to_sym, @config.deliver_params
          $logger.info { "#{@id}: Sending item to #{mail.to.join(', ')} via #{deliver_method || 'default'}: #{mail.subject.inspect}" }
          case deliver_method.to_sym
          when :maildir
            location = deliver_params[:location] or raise Error, "location not found in deliver_params"
            location = Path.new(location).expand_path
            components = @id.split('/')
            path = (components.length == 1) ? components.first : components[0..-2].join('.')
            maildir = Maildir.new(location / ('.' + path))
            maildir.serializer = Maildir::Serializer::Mail.new
            maildir.add(mail)
          else
            mail.delivery_method(deliver_method, deliver_params) if deliver_method
            mail.perform_deliveries = true
            mail.deliver!
          end
        end

        def render_item(item)
          make_styles unless @styles
          Simple::Builder.html4_document do |html|
            html.html do
              html.head do
                html.meta(name: 'x-apple-disable-message-reformatting')
                html.meta(name: 'viewport', content: 'width=device-width, initial-scale=1')
                @styles.each do |style|
                  html.style { html << style }
                end
              end
              html.body do
                html.div(class: 'header') do
                  html << ('%s [%s]' % [@config.title || @title, @id]).to_html
                end
                html << item.to_html
              end
            end
          end.to_html
        end

        def make_styles
          raise Error, "dir not set" unless @dir
          @styles = [@config.main_stylesheet, @config.aux_stylesheets].compact.map do |file|
            file = Path.new(file)
            file = @dir / file if file.relative?
            SassC::Engine.new(file.read, syntax: :scss, style: :compressed).render
          end
        end

      end

      class Item

        attr_accessor :id
        attr_accessor :date
        attr_accessor :title
        attr_accessor :uri
        attr_accessor :author

        include SetParams
        include Simple::Printer::Printable

        def printable
          [
            [:id, 'ID'],
            :date,
            :title,
            :uri,
            :author,
          ]
        end

        def eql?(other)
          @id.eql?(other.id)
        end

        def ==(other)
          @id == other&.id
        end

        def age
          Time.now - @date
        end

        def date_str
          @date.strftime('%e %B %Y')
        end

        def scrub_html(html)
          Loofah.fragment(html).
            scrub!(:prune).
            scrub!(Scrubber::RemoveExtras).
            scrub!(Scrubber::RemoveVoxFooter).
            scrub!(Scrubber::RemoveStyling).
            scrub!(Scrubber::ReplaceBlockquote).
            to_html
        end

        def text_to_html(text)
          Simple::Builder.html_fragment do |html|
            text.split("\n").each_with_index do |line, i|
              html.br unless i == 0
              html.text(line)
            end
          end.to_html
        end

      end

    end

  end

end