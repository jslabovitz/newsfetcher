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

  def make_email
    fields = {
      'p' => @subscription.relative_dir.dirname.each_filename.to_a.join('.'),
      'i' => @subscription.id,
      't' => @title,
    }
    mail = Mail.new
    mail.date =         @date
    mail.from =         @profile.mail_from
    mail.to =           NewsFetcher.replace_fields(@profile.mail_to, fields)
    mail.subject =      NewsFetcher.replace_fields(@profile.mail_subject, fields)
    mail.content_type = 'text/html'
    mail.charset      = 'utf-8'
    mail.body         = render.to_html
    mail
  end

  def render
    NewsFetcher.html_document do |html|
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
        html.h2 { html.a(PublicSuffix.domain(@url.host), href: @url) }
        html.h3(@author) if @author
        html.div(class: 'content') { html << @content }
        if @subscription_description
          html.div(class: 'bar') do
            html.text(@subscription_description)
          end
        end
      end
    end
  end

  def is_html?(str)
    str =~ /(<[a-z]+>)|(\&\S+;)/i
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