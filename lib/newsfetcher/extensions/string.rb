class String

  def strip_html
    if html?
      Loofah.
        fragment(self).
        text(encode_special_chars: false)
    else
      self
    end
  end

  def html?
    self =~ /(<[a-z]+)|(\&\S+;)/i
  end

  def to_html
    if html?
      self
    else
      RubyPants.new(self).to_html
    end
  end

end