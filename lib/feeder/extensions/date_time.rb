class Date

  def to_json(*)
    iso8601.to_json
  end

end

class Time

  def to_json(*)
    iso8601.to_json
  end

end