module NewsFetcher

  class Item

    attr_accessor :subscription
    attr_reader   :id
    attr_reader   :date
    attr_reader   :title
    attr_reader   :url
    attr_reader   :author
    attr_reader   :content

    def initialize(subscription:, **params)
      @subscription = subscription
      params.each { |k, v| send("#{k}=", v) }
    end

    def id=(id)
      @id = (s = id.to_s.strip).empty? ? nil : s
    end

    def date=(date)
      @date = case date
      when String
        Time.parse(date)
      when Time, nil
        date
      else
        raise Error, "Unknown date value: #{date.inspect}"
      end
    end

    def title=(title)
      @title = (s = title.to_s.strip).empty? ? nil : s
    end

    def url=(url)
      @url = case url
      when String
        Addressable::URI.parse(url.strip)
      when Addressable::URI, URI, nil
        url
      else
        raise Error, "Unknown URL value: #{url.inspect}"
      end
    end

    def author=(author)
      @author = (s = author.to_s.strip).empty? ? nil : s
    end

    def content=(content)
      @content = (s = content.to_s.strip).empty? ? nil : s
    end

    def digest
      # NOTE: we *don't* include date or ID, as we're trying to avoid sending similar items
      str = [@title, @author, @url, @content].join(',')
      digest = OpenSSL::Digest.digest('SHA384', str)
      digest.unpack('H*').join
    end

    def to_info
      %i[id date title author url].map do |key|
        value = send(key)
        value = '-' if value.nil?
        '%s="%s"' % [key, value]
      end.join(', ')
    end

    def make_email
      fields = {
        'p' => @subscription.relative_dir.dirname.each_filename.to_a.join('.'),
        'i' => @subscription.id,
        'b' => @subscription.base_id,
        't' => strip_html(@title),
      }
      mail = Mail.new
      mail.date =         @date
      mail.from =         @subscription.profile.mail_from
      mail.to =           replace_fields(@subscription.profile.mail_to, fields)
      mail.subject =      replace_fields(@subscription.profile.mail_subject, fields)
      mail.content_type = 'text/html'
      mail.charset      = 'utf-8'
      {
        'ID' => @id,
        'Date' => @date,
        'Title' => @title,
        'Author' => @author,
        'URL' => @url,
      }.compact.each { |k, v| mail["X-Newsfetcher-#{k}"] = v.to_s }
      mail.body         = render.to_html
      mail
    end

    def render
      html_document do |html|
        html.head do
          html.meta(name: 'x-apple-disable-message-reformatting')
          html.meta(name: 'viewport', content: 'width=device-width, initial-scale=1')
          @subscription.profile.styles.each do |style|
            html.style { html << style }
          end
        end
        html.body do
          html.div(class: 'header') do
            html.text('%s [%s]' % [@subscription.title, @subscription.id])
          end
          html.h1 do
            if is_html?(@title)
              html << @title
            else
              html.text(@title)
            end
          end
          html.h2 do
            if @author
              html.text(@author)
              html.br
            end
            html.text(@date.strftime('%e %B %Y').strip)
          end
          if @url
            html.h3 do
              html.a(pretty_url, href: @url)
            end
          end
          if @content
            html.div(class: 'content') { html << render_content }
          end
        end
      end
    end

    def age
      Time.now - @date
    end

    DefaultKeys = %i{id date title url author content}

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

    def render_content
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
      if is_html?(@content)
        Loofah.fragment(@content).
          scrub!(:prune).
          scrub!(remove_beacon).
          scrub!(remove_feedflare).
          scrub!(remove_vox_footer).
          scrub!(remove_font).
          scrub!(remove_form).
          scrub!(remove_styling).
          scrub!(replace_blockquote).
          to_html
      else
        html_fragment do |html|
          @content.split("\n").each_with_index do |line, i|
            html.br unless i == 0
            html.text(line)
          end
        end.to_html
      end
    end

    def html_document(&block)
      doc = Nokogiri::HTML::Document.new
      doc.encoding = 'UTF-8'
      Nokogiri::HTML::Builder.with(doc) do |html|
        html.html do
          yield(html) if block_given?
        end
      end
      doc
    end

    def html_fragment(&block)
      fragment = Nokogiri::HTML::DocumentFragment.parse('')
      Nokogiri::HTML::Builder.with(fragment) do |html|
        yield(html) if block_given?
      end
      fragment
    end

    def replace_fields(str, fields)
      str.to_s.gsub(/%(\w)/) do
        raise Error, "Unknown tag: #{$1.inspect}" unless fields.has_key?($1)
        fields[$1] || ''
      end
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

    def pretty_url
      if @url
        url2 = @url.dup
        if url2.query
          url2.query_values = url2.query_values.tap do |query|
            query.delete_if { |k, v| k =~ /^utm_/ || k == 'icid' }
          end
          url2.query = nil if url2.query_values.empty?
        end
        url2.host = url2.host.sub(/^www\./, '')
        url2.to_s.sub(%r{^https?://}, '')
      else
        ''
      end
    end

  end

end