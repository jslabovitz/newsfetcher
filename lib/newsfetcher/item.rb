class Item

  attr_accessor :feed
  attr_accessor :entry
  attr_accessor :profile
  attr_accessor :style
  attr_accessor :subscription
  attr_accessor :id
  attr_accessor :date
  attr_accessor :subscription_title
  attr_accessor :subscription_description
  attr_accessor :title
  attr_accessor :url
  attr_accessor :author
  attr_accessor :image
  attr_accessor :content

  def initialize(feed:, entry:, profile:, subscription:)
    @feed = feed
    @entry = entry
    @profile = profile
    @style = profile.style
    @subscription = subscription
    @id = entry.entry_id || entry.url or raise Error, "Can't determine entry ID"
    @id = @id.to_s
    @date = entry.published || Time.now
    @subscription_title = subscription.title || feed.title || 'untitled'
    @subscription_description = feed.respond_to?(:description) ? feed.description : nil
    @title = (t = entry.title.to_s.strip).empty? ? 'untitled' : t
    @url = URI.parse(entry.url) if entry.url
    @author = entry.respond_to?(:author) ? entry.author : nil
    @image = entry.respond_to?(:image) ? entry.image : nil
    @content = entry.content || entry.summary || ''
  end

  def make_email
    fields = {
      'p' => @subscription.relative_dir.dirname.each_filename.to_a.join('.'),
      'i' => @subscription.id,
      'b' => @subscription.base_id,
      't' => @title,
    }
    mail = Mail.new
    mail.date =         @date
    mail.from =         @profile.mail_from
    mail.to =           replace_fields(@profile.mail_to, fields)
    mail.subject =      replace_fields(@profile.mail_subject, fields)
    mail.content_type = 'text/html'
    mail.charset      = 'utf-8'
    mail.body         = render.to_html
    mail
  end

  def render
    html_document do |html|
      html.head do
        html.style { html << @style }
      end
      html.body do
        html.div(class: 'bar') do
          html.text(@subscription_title)
        end
        html.h1 do
          if is_html?(@title)
            html << @title
          else
            html.text(@title)
          end
        end
        html.h2 { html.a(PublicSuffix.domain(@url.host), href: @url) } if @url
        html.h3(@author) if @author
        html.div(class: 'content') { html << render_content }
        if @subscription_description
          html.div(class: 'bar') do
            html.text(@subscription_description)
          end
        end
      end
    end
  end

  def age
    Time.now - @date
  end

  DefaultKeys = %i{id date subscription_title subscription_description title url author image content}

  def show(keys)
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
    if is_html?(@content)
      Loofah.fragment(@content).
        scrub!(:prune).
        scrub!(remove_beacon).
        scrub!(remove_feedflare).
        scrub!(remove_font).
        scrub!(remove_form).
        scrub!(remove_styling).
        to_html
    else
      html_fragment { |h| h.pre(@content) }.to_html
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
      fields[$1] or raise Error, "Unknown tag: #{$1.inspect}"
    end
  end

  def is_html?(str)
    str =~ /(<[a-z]+)|(\&\S+;)/i
  end

end