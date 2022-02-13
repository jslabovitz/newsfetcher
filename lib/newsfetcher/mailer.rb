module NewsFetcher

  class Mailer

    attr_accessor :item
    attr_accessor :subscription
    attr_accessor :profile

    include SetParams

    def self.send_mail(params={})
      new(params).tap(&:send_mail)
    end

    def initialize(params={})
      set(params)
      setup_scrubbers
    end

    def setup_scrubbers
      @remove_vox_footer = Loofah::Scrubber.new do |node|
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
      @remove_extras = Loofah::Scrubber.new do |node|
        if node.name == 'div' && node['class'] == 'feedflare'
          node.remove
        elsif node.name == 'img' && node['height'] == '1' && node['width'] == '1'
          node.remove
        elsif node.name == 'form'
          node.replace(node.children)
        end
      end
      @remove_styling = Loofah::Scrubber.new do |node|
        if %w{font big small}.include?(node.name)
          node.replace(node.children)
        else
          node.remove_attribute('style') if node['style']
          node.remove_attribute('class') if node['class']
          node.remove_attribute('id') if node['id']
        end
      end
      @replace_blockquote = Loofah::Scrubber.new do |node|
        if node.name == 'blockquote'
          node.name = 'div'
          node['class'] = 'blockquote'
        end
      end
    end

    def mail_from
      ERB.new(@profile.mail_from).result(binding)
    end

    def mail_to
      ERB.new(@profile.mail_to).result(binding)
    end

    def send_mail
      template = Path.new(MessageTemplateFileName).read
      msg = ERB.new(template).result(binding)
      mail = Mail.new(msg)
      mail.delivery_method(*@profile.delivery_method)
      $logger.info { "#{@subscription.id}: Sending item: #{@item.title.inspect}" }
      mail.deliver!
    end

    def styles
      Simple::Builder.html_fragment do |html|
        @profile.styles.each do |style|
          html.style { html << style }
        end
      end.to_html
    end

    def mail_body
      template = Path.new(HTMLTemplateFileName).read
      ERB.new(template).result(binding)
    end

    def item_content_html
      if @item.content
        if @item.content.html?
          render_html_item_content
        else
          render_text_item_content
        end
      else
        ''
      end
    end

    def render_html_item_content
      Loofah.fragment(@item.content).
        scrub!(:prune).
        scrub!(@remove_extras).
        scrub!(@remove_vox_footer).
        scrub!(@remove_styling).
        scrub!(@replace_blockquote).
        to_html
    end

    def render_text_item_content
      Simple::Builder.html_fragment do |html|
        @item.content.split("\n").each_with_index do |line, i|
          html.br unless i == 0
          html.text(line)
        end
      end.to_html
    end

  end

end