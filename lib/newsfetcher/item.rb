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
    @content = NewsFetcher.parse_content(entry.content || entry.summary).to_html
  end

  def subscription_site
    @url ? PublicSuffix.domain(@url.host) : ''
  end

  def make_email
    mail = Mail.new
    mail.date =         @date
    mail.from =         @profile.mail_from
    mail.to =           @profile.mail_address_for_subscription(@subscription)
    mail.subject =      "[%s] %s" % [@subscription.id, @title]
    mail.content_type = 'text/html; charset=UTF-8'
    mail.body         = render.to_html
    mail
  end

  def render
    NewsFetcher.html_document do |html|
      html.head do
        html.style { html << @style }
      end
      html.body do
        html.div(class: 'bar') { html << make_header }
        html.h1 { html.a(title, href: @url) }
        html.div(class: 'content') { html << @content }
        html.div(@subscription_description, class: 'bar')
      end
    end
  end

  def make_header
    %i{subscription_title author subscription_site}.map do |key|
      make_header_part(key)
    end.compact.join(' // ')
  end

  def make_header_part(key)
    value = send(key)
    if value && !value.empty?
      NewsFetcher.html_fragment do |h|
        h.span(value, class: key.to_s.gsub('_', '-'))
      end.to_html
    else
      nil
    end
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

end