module NewsFetcher

  class Formatter

    attr_accessor :styles
    attr_accessor :subscription

    include SetParams

    def make_mail(item:)
      mail_from    = @subscription.config.mail_from or raise Error, "mail_from not specified in config"
      mail_to      = @subscription.config.mail_to or raise Error, "mail_to not specified in config"
      mail_subject = @subscription.config.mail_subject or raise Error, "mail_subject not specified in config"
      fields = {
        subscription_id: @subscription.id,
        item_title: item.title,
      }
      mail = Mail.new
      mail.date =         item.date
      mail.from =         ERB.new(mail_from).result_with_hash(fields)
      mail.to =           ERB.new(mail_to).result_with_hash(fields)
      mail.subject =      ERB.new(mail_subject).result_with_hash(fields)
      mail.content_type = 'text/html'
      mail.charset =      'utf-8'
      mail.body =         item_to_html(item)
      mail
    end

    def item_to_html(item)
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
              html << ('%s [%s]' % [@subscription.effective_title, @subscription.id]).to_html
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
                html << scrub_html(item.content)
              else
                html << text_to_html(item.content)
              end
            end
          end
        end
      end.to_html
    end

    def scrub_html(html)
      Loofah.fragment(html).
        scrub!(:prune).
        scrub!(RemoveExtras).
        scrub!(RemoveVoxFooter).
        scrub!(RemoveStyling).
        scrub!(ReplaceBlockquote).
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

    RemoveVoxFooter = Loofah::Scrubber.new do |node|
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

    RemoveExtras = Loofah::Scrubber.new do |node|
      if node.name == 'div' && node['class'] == 'feedflare'
        node.remove
      elsif node.name == 'img' && node['height'] == '1' && node['width'] == '1'
        node.remove
      elsif node.name == 'form'
        node.replace(node.children)
      end
    end

    RemoveStyling = Loofah::Scrubber.new do |node|
      if %w{font big small}.include?(node.name)
        node.replace(node.children)
      else
        node.remove_attribute('style') if node['style']
        node.remove_attribute('class') if node['class']
        node.remove_attribute('id') if node['id']
      end
    end

    ReplaceBlockquote = Loofah::Scrubber.new do |node|
      if node.name == 'blockquote'
        node.name = 'div'
        node['class'] = 'blockquote'
      end
    end

  end

end