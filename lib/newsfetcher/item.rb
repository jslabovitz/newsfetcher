module NewsFetcher

  class Item

    attr_accessor :id
    attr_accessor :date
    attr_accessor :title
    attr_accessor :uri
    attr_accessor :author
    attr_accessor :content

    include SetParams
    include Simple::Printer::Printable

    def initialize(entry)
      if entry.url
        begin
          uri = Addressable::URI.parse(entry.url.strip)
        rescue Addressable::URI::InvalidURIError => e
          raise Error, "Can't parse URL for entry: #{entry.url.inspect}"
        end
      else
        uri = nil
      end
      id = entry.entry_id || uri or raise Error, "Can't determine ID or URL for entry"
      super(
        id: id.to_s,
        uri: uri,
        date: entry.published || Time.now,
        title: entry.title,
        author: entry.respond_to?(:author) ? entry.author&.sub(/^by\s+/i, '') : nil,
        content: (entry.content || entry.summary)&.to_s,
      )
    end

    def printable
      [
        [:id, 'ID'],
        :date,
        :title,
        :uri,
        :author,
      ]
    end

    def eql?(other)
      @id.eql?(other.id)
    end

    def ==(other)
      @id == other&.id
    end

    def age
      Time.now - @date
    end

    def date_str
      @date.strftime('%e %B %Y')
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
      Simple::Builder.build_html do |html|
        text.split("\n").each_with_index do |line, i|
          html.br unless i == 0
          html.text(line)
        end
      end.to_html
    end

    def to_html
      Simple::Builder.build_html do |html|
        if @title
          html.h1 do
            html << @title.to_html
          end
        end
        html.h2 do
          html << [date_str, @author].compact.join(' • ').to_html
        end
        if @uri
          html.h3 do
            html.a(@uri.prettify, href: @uri)
          end
        end
        if @content
          html << (@content.html? ? scrub_html(@content) : text_to_html(@content))
        end
      end
    end

  end

end