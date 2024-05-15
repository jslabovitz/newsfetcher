module NewsFetcher

  class Subscription

    attr_accessor :id
    attr_accessor :dir
    attr_accessor :config
    attr_accessor :styles
    attr_accessor :items
    attr_accessor :title

    include SetParams
    include Simple::Printer::Printable

    def initialize(**params)
      @title = nil
      @items = []
      super
      @item_history = History.new(file: item_history_file, index_key: :id)
      @response_history = History.new(file: response_history_file)
    end

    def inspect
      to_s
    end

    def printable
      [
        [:id, 'ID'],
        { label: 'URI', value: @config.uri },
        :dir,
        :title,
        :status,
        { label: 'Age', value: (a = age) ? '%d days' % (a / DaySecs) : 'never' },
        { label: 'Disabled', value: @config.disabled },
        { label: 'Last response', value: format_response_history_entry(@response_history.last_entry) },
        :items,
      ]
    end

    def format_response_history_entry(entry)
      if entry
        '%s (%s) at %s' % [entry.status, entry.reason, entry.time]
      else
        'none'
      end
    end

    def item_history_file
      raise Error, "dir not set" unless @dir
      @dir / ItemHistoryFileName
    end

    def response_history_file
      raise Error, "dir not set" unless @dir
      @dir / ResponseHistoryFileName
    end

    def age
      entry = @item_history.last_entry or return nil
      Time.now - entry.time
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

    def make_dotted_folder
      components = @id.split('/')
      components.pop if @config.consolidate && components.length > 1
      components.unshift(@config.root_folder) if @config.root_folder
      components.join('.')
    end

    def update_item_history
      @items.each do |item|
        @item_history << { time: item.date, id: item.id }
      end
    end

    def prune_item_history
      @item_history.prune(before: Time.now - @config.max_age).each do |entry|
        $logger.info { "pruned #{entry.id.inspect} (#{entry.time})"}
      end
    end

    def prune_response_history
      @response_history.prune(before: Time.now - @config.max_age).each do |entry|
        $logger.info { "pruned response from #{entry.time}" }
      end
    end

    def update
      $logger.debug { "#{@id}: updating" }
      begin
        prune_item_history
        prune_response_history
        if recently_updated?
          $logger.info { "#{@id}: too soon to update" }
          return
        end
        get
        reject_items
        update_item_history
        deliver
      rescue Error => e
        $logger.error { "#{@id}: #{e}" }
      end
    end

    def recently_updated?
      (entry = @response_history.last_entry) &&
        # (200...400).include?(entry.status) &&
        Time.now - entry.time < @config.update_interval
    end

    def get
      fetcher = Fetcher.get(@config.uri)
      @response_history << {
        time: Time.now,
        status: fetcher.response_status,
        reason: fetcher.response_reason,
      }
      if fetcher.success?
        if fetcher.moved && !@config.ignore_moved
          $logger.warn { "#{@id}: URI #{@config.uri} moved to #{fetcher.actual_uri}" }
        end
        feed = fetcher.parse_feed
        @title = @config.title || feed[:title]
        @items = feed[:items]
      else
        $logger.warn { "#{@id}: HTTP error #{fetcher.response_status} (#{fetcher.response_reason})" }
      end
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
      elsif @item_history[item.id]
        'seen item'
      elsif @config.ignore_uris.find { |r| item.uri.to_s =~ r }
        'ignored item'
      end
    end

    def deliver
      $logger.debug { "#{@id}: no items to deliver" } if @items.empty?
      @items.sort_by(&:date).each do |item|
        deliver_item(item)
      end
    end

    def reset
      @item_history.reset
    end

    def fix
    end

    def deliver_item(item)
      folder = make_dotted_folder
      fields = {
        subscription_id: @id,
        item_title: item.title,
        subscription_folder: folder,
      }
      mail = Mail.new
      mail.date =         item.date
      mail.from =         ERB.new(@config.mail_from).result_with_hash(fields)
      mail.to =           ERB.new(@config.mail_to).result_with_hash(fields)
      mail.subject =      ERB.new(@config.mail_subject).result_with_hash(fields)
      mail.content_type = 'text/html'
      mail.charset =      'utf-8'
      mail.body =         build_item_html(item)
      delivery_method = @config.delivery_method&.to_sym
      delivery_params = @config.delivery_params
      $logger.info {
        "#{@id}: Sending item to %s in folder %s via %s: %p" % [
          mail.to.join(', '),
          folder,
          delivery_method || '<default>',
          mail.subject,
        ]
      }
      if delivery_method == :maildir
        delivery_method = Mail::Maildir
        delivery_dir = Path.new(delivery_params[:dir]) / ".#{folder}"
        delivery_params = delivery_params.merge(dir: delivery_dir.to_s)
      end
      mail.delivery_method(delivery_method, **delivery_params) if delivery_method
      mail.deliver!
    end

    def build_item_html(item)
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
              html << ('%s [%s]' % [@title, @id]).to_html
            end
            if item.title
              html.h1 do
                html << item.title.to_html
              end
            end
            html.h2 do
              html << [
                item.date.strftime('%e %B %Y'),
                item.author,
              ].compact.join(' • ').to_html
            end
            if item.uri
              html.h3 do
                html.a(item.uri.prettify, href: item.uri)
              end
            end
            if item.content
              if item.content.html?
                html << Scrubber.scrub_html(item.content)
              else
                html << Scrubber.text_to_html(item.content)
              end
            end
          end
        end
      end.to_html
    end

  end

end