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

        def self.type
          to_s.split('::')[-2].downcase
        end

        def initialize(params={})
          set(params)
          if @dir && history_file.exist?
            @history = History.load(history_file)
            @history.prune(before: Time.now - @config.dormant_time)
            @history.save(history_file)
          else
            @history = History.new
          end
          @title = nil
          @items = []
        end

        def inspect
          to_s
        end

        def path(delim='/')
          @id.split('/')[0..-2].join(delim)
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
          if (time = @history.last_time)
            Time.now - time
          else
            nil
          end
        end

        def status
          if (a = age)
            if a > @config.dormant_time
              :dormant
            else
              :active
            end
          else
            :new
          end
        end

        def update
          begin
            get
            process
          rescue Error => e
            $logger.error { "#{@id}: #{e}" }
          end
        end

        def get
          raise NotImplementedError, "#{__method__} needs to be implemented in subclass"
        end

        def process
          ignore_patterns = @config.ignore ? [@config.ignore].flatten.map { |r| Regexp.new(r) } : nil
          @items.reject { |item|
            (ignore_patterns && ignore_patterns.find { |r| item.uri.to_s =~ r }) \
            || @history.include?(item.id) \
            || item.age > @config.dormant_time
           }.each do |item|
            send_mail(make_mail(item))
            @history[item.id] = item.published
            @history.save(history_file)
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

        Fields = {
          id: { label: 'ID', format: '%-30.30s' },
          type: { label: 'Type', format: '%-10.10s' },
          title: { label: 'Title', format: '%-30.30s' },
          status: { label: 'Status', format: '%-10s' },
          age: { label: 'Age', format: '%-10s' },
        }
        FieldsMaxWidth = Fields.map { |k, v| v[:label].length }.max

        def print(io=STDOUT, format: nil)
          fields = {
            id: @id,
            type: self.class.type,
            title: @title,
            status: status,
            age: ((a = age) ? '%d days' % (a / 60 / 60 / 24) : 'never'),
          }
          case format
          when nil, :table
            io.puts(
              fields.map do |key, value|
                field = Fields[key] or raise
                field[:format] % value
              end.join(' | ')
            )
          when :list
            fields.each do |key, value|
              field = Fields[key] or raise
              io.puts '%*s: %s' % [
                FieldsMaxWidth,
                field[:label],
                value,
              ]
            end
            io.puts
          else
            raise
          end
        end

        def make_mail(item)
          mail_from    = @config.mail_from or raise Error, "mail_from not specified in config"
          mail_to      = @config.mail_to or raise Error, "mail_to not specified in config"
          mail_subject = @config.mail_subject or raise Error, "mail_subject not specified in config"
          fields = {
            subscription_id: @id,
            item_subject: item.summary,
          }
          mail = Mail.new
          mail.date =         item.published
          mail.from =         ERB.new(mail_from).result_with_hash(fields)
          mail.to =           ERB.new(mail_to).result_with_hash(fields)
          mail.subject =      ERB.new(mail_subject).result_with_hash(fields)
          mail.content_type = 'text/html'
          mail.charset =      'utf-8'
          mail.body =         render_item(item).to_html
          mail
        end

        def send_mail(mail)
          deliver_method, deliver_params =
            @config.deliver_method&.to_sym, @config.deliver_params
          $logger.info { "#{@id}: Sending item via #{deliver_method || 'default'}: #{mail.subject.inspect}" }
          case deliver_method.to_sym
          when :maildir
            location = deliver_params[:location] or raise Error, "location not found in deliver_params"
            dir = Path.new(location).expand_path
            folder = '.' + path('.')
            maildir = Maildir.new(dir / folder)
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
                if item.title
                  html.h1 do
                    html << item.title.to_html
                  end
                end
                html.h2 do
                  html << [
                    item.published.strftime('%e %B %Y'),
                    item.author,
                  ].compact.join(' • ').to_html
                end
                if item.uri
                  html.h3 do
                    html.a(item.uri.prettify, href: item.uri)
                  end
                end
                html.div(class: 'content') { html << item.content }
              end
            end
          end
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

        attr_accessor :object

        def initialize(object)
          @object = object
        end

        def id
          raise NotImplementedError, "#{__method__} not implemented"
        end

        def published
          raise NotImplementedError, "#{__method__} not implemented"
        end

        def summary
          title
        end

        def title
          raise NotImplementedError, "#{__method__} not implemented"
        end

        def uri
          raise NotImplementedError, "#{__method__} not implemented"
        end

        def author
          raise NotImplementedError, "#{__method__} not implemented"
        end

        def content
          raise NotImplementedError, "#{__method__} not implemented"
        end

        def eql?(other)
          id.eql?(other.id)
        end

        def ==(other)
          id == other.id
        end

        def age
          Time.now - published
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

        DefaultKeys = %i{id published title uri author content}

        def show(keys=nil)
          keys ||= DefaultKeys
          keys.each do |key|
            value = send(key)
            if value =~ /\n/
              puts '%20s:' % key
              value.split(/\n/).each { |v| puts '  | %s' % v }
            else
              puts '%20s: %s' % [key, value]
            end
          end
        end

      end

    end

  end

end