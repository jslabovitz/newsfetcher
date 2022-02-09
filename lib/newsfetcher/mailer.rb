module NewsFetcher

  class Mailer

    attr_accessor :item
    attr_accessor :subscription
    attr_accessor :profile

    include SetParams

    def self.send_mail(params={})
      new(params).tap(&:send_mail)
    end

    def send_mail
      fields = {
        'id' => @subscription.id,
        'id_path' => @subscription.id.split('/').join('.'),
        'stripped_title' => strip_html(@item.title),
      }
      mail = Mail.new
      mail.date =         @item.date
      mail.from =         @profile.mail_from
      mail.to =           ERB.new(@profile.mail_to).result_with_hash(fields)
      mail.subject =      ERB.new(@profile.mail_subject).result_with_hash(fields)
      mail.content_type = 'text/html'
      mail.charset      = 'utf-8'
      {
        'ID' => @item.id,
        'Date' => @item.date,
        'Title' => @item.title,
        'Author' => @item.author,
        'URI' => @item.uri,
      }.compact.each { |k, v| mail["X-Newsfetcher-#{k}"] = v.to_s }
      mail.body = render
      mail.delivery_method(*@profile.delivery_method)
      $logger.info { "#{@subscription.id}: Sending item: #{@item.title.inspect}" }
      mail.deliver!
    end

    def render
      doc = Nokogiri::HTML::Document.new
      doc.encoding = 'UTF-8'
      Nokogiri::HTML::Builder.with(doc) do |html|
        html.html do
          html.head do
            html.meta(name: 'x-apple-disable-message-reformatting')
            html.meta(name: 'viewport', content: 'width=device-width, initial-scale=1')
            @profile.styles.each do |style|
              html.style { html << style }
            end
          end
          html.body do
            html.div(class: 'header') do
              html.text('%s [%s]' % [@subscription.title, @subscription.id])
            end
            html.h1 do
              if is_html?(@item.title)
                html << @item.title
              else
                html.text(@item.title)
              end
            end
            html.h2 do
              html.text(
                [@item.author, @item.date.strftime('%e %B %Y')]
                  .map(&:to_s)
                  .map(&:strip)
                  .reject(&:empty?)
                  .join(' • ')
              )
            end
            html.h3 do
              html.a(pretty_uri, href: @item.uri)
            end
            html.div(class: 'content') do
              if @item.content
                if is_html?(@item.content)
                  html << render_html_content
                else
                  html << render_text_content
                end
              end
            end
          end
        end
      end.to_html
    end

    def render_html_content
      remove_feedflare = Loofah::Scrubber.new do |node|
        node.remove if node.name == 'div' && node['class'] == 'feedflare'
      end
      remove_vox_footer = Loofah::Scrubber.new do |node|
        if node.text == 'Help keep Vox free for all'
          n = node
          while (n = n.previous)
            if n.name == 'hr'
              n.remove
              break
            end
          end
          while node.next
            node.next.remove
          end
          node.remove
          Loofah::Scrubber::STOP
        end
      end
      remove_beacon = Loofah::Scrubber.new do |node|
        node.remove if node.name == 'img' && node['height'] == '1' && node['width'] == '1'
      end
      remove_font = Loofah::Scrubber.new do |node|
        node.replace(node.children) if %w{font big small}.include?(node.name)
      end
      remove_form = Loofah::Scrubber.new do |node|
        node.replace(node.children) if node.name == 'form'
      end
      remove_styling = Loofah::Scrubber.new do |node|
        node.remove_attribute('style') if node['style']
        node.remove_attribute('class') if node['class']
        node.remove_attribute('id') if node['id']
      end
      replace_blockquote = Loofah::Scrubber.new do |node|
        if node.name == 'blockquote'
          node.name = 'div'
          node['class'] = 'blockquote'
        end
      end
      Loofah.fragment(@item.content).
        scrub!(:prune).
        scrub!(remove_beacon).
        scrub!(remove_feedflare).
        scrub!(remove_vox_footer).
        scrub!(remove_font).
        scrub!(remove_form).
        scrub!(remove_styling).
        scrub!(replace_blockquote).
        to_html
    end

    def render_text_content
      fragment = Nokogiri::HTML::DocumentFragment.parse('')
      Nokogiri::HTML::Builder.with(fragment) do |html|
        @item.content.split("\n").each_with_index do |line, i|
          html.br unless i == 0
          html.text(line)
        end
      end.to_html
    end

    def strip_html(str)
      if is_html?(str)
        Loofah.
          fragment(str).
          text(encode_special_chars: false)
      else
        str
      end
    end

    def is_html?(str)
      str =~ /(<[a-z]+)|(\&\S+;)/i
    end

    def pretty_uri
      if @item.uri
        uri2 = @item.uri.dup
        if uri2.query
          uri2.query_values = uri2.query_values.tap do |query|
            query.delete_if { |k, v| k =~ /^utm_/ || k == 'icid' }
          end
          uri2.query = nil if uri2.query_values.empty?
        end
        case uri2.scheme
        when 'http', 'https'
          uri2.host = uri2.host.sub(/^www\./, '')
          uri2.to_s.sub(%r{^https?://}, '')
        when 'mailto'
          uri2.path.to_s
        else
          uri2.to_s
        end
      else
        ''
      end
    end

  end

end