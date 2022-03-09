class String

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