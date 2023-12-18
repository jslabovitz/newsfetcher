require 'maildir'

module Mail

  class Maildir

    attr_accessor :settings

    def initialize(values)
      self.settings = values
    end

    def deliver!(mail)
      dir = settings[:dir] or raise Error, "'dir' not found in settings"
      maildir = ::Maildir.new(dir)
      maildir.serializer = ::Maildir::Serializer::Mail.new
      maildir.add(mail)
    end

  end

end