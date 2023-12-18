module NewsFetcher

  module Scrubber
    
    def self.scrub_html(html)
      Loofah.fragment(html).
        scrub!(:prune).
        scrub!(RemoveExtras).
        scrub!(RemoveVoxFooter).
        scrub!(RemoveStyling).
        scrub!(ReplaceBlockquote).
        to_html
    end

    def self.text_to_html(text)
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