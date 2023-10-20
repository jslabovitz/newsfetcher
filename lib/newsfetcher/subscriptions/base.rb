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

        def self.inherited(subclass)
          @@classes ||= []
          @@classes << subclass
        end

        def self.classes
          @@classes
        end

        def self.type
          to_s.split('::')[-2].downcase
        end

        def self.make_id(uri:, id: nil, path: nil)
          id ||= derive_id(uri)
          id = "#{path}/#{id}" if path
          id
        end

        def self.derive_id(uri)
          [
            uri.host.to_s \
              .sub(/^(www|ssl|en|feeds|rss|blogs?|news).*?\./i, '') \
              .sub(/\.(com|org|net|info|edu|co\.uk|wordpress\.com|blogspot\.com|feedburner\.com)$/i, ''),
            uri.path.to_s \
              .gsub(/\b(\.?feeds?|index|atom|rss|rss2|xml|rdf|php|blog|posts|default)\b/i, ''),
            uri.query.to_s \
              .gsub(/\b(format|feed|type|q)=(atom|rss\.xml|rss2?|xml)/i, ''),
          ] \
            .join(' ')
            .downcase
            .gsub(/[^a-z0-9]+/, ' ')  # non-alphanumeric
            .strip
            .gsub(/\s+/, '-')
        end

        def initialize(params={})
          @title = nil
          @items = []
          super
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
            [:disable, 'Disable', config.disable],
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
            @history.save
          elsif @dir
            @history = History.new(file: history_file)
          else
            @history = History.new
          end
        end

        def update_history
          @items.each do |item|
            #FIXME: make entry with timestamp
            @history[item.id] = item.date
          end
          @history.save
        end

        def update
          $logger.debug { "#{@id}: updating" }
          begin
            get
            reject_items
            update_history
            deliver
          rescue Error => e
            $logger.error { "#{@id}: #{e}" }
          end
        end

        def get
          # implemented in subclass
        end

        def reject_items
          @items.reject! do |item|
            if (reason = reject_item?(item))
              $logger.debug { "#{@id}: removing item: #{reason} #{item.id}" }
              true
            end
          end
        end

        def reject_item?(item)
          if item.age > @config.max_age
            'outdated item'
          elsif @history.include?(item.id)
            'seen item'
          else
            nil
          end
        end

        def deliver
          $logger.debug { "#{@id}: no items to deliver" } if @items.empty?
          @items.sort_by(&:date).each do |item|
            send_mail(make_mail(item))
          end
        end

        def enable
          @config.disable = false
          save
        end

        def disable
          @config.disable = true
          save
        end

        def reset
          @history.reset
        end

        def remove
          raise Error, "dir not set" unless @dir
          @dir.rmtree
        end

        def fix
          @history.save
        end

        def edit
          editor = ENV['EDITOR'] or raise Error, "No editor defined in $EDITOR"
          system(editor, config_file.to_s)
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
            folder = deliver_params[:folder]
            dir = maildir_directory(location: location, folder: folder)
            maildir = Maildir.new(dir)
            maildir.serializer = Maildir::Serializer::Mail.new
            maildir.add(mail)
          else
            mail.delivery_method(deliver_method, deliver_params) if deliver_method
            mail.perform_deliveries = true
            mail.deliver!
          end
        end

        def maildir_directory(location:, folder:)
          location = Path.new(location).expand_path
          components = @id.split('/')
          components.pop if @config.consolidate && components.length > 1
          components.unshift(folder) if folder
          components.unshift('')
          location / components.join('.')
        end

        def render_item(item)
          make_styles unless @styles
          Simple::Builder.build_html4_document do |html|
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
          Simple::Builder.build_html do |html|
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