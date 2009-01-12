require 'net/imap'

class Imap < RemoteMail
  DEFAULT_PORT = 143
  DEFAULT_SSL_PORT = 993

  RemoteMailHelper::setup_columns( self )
  column :old_ssl , :boolean

  attr_reader :mailer

  def setup_mailer
    if self.ssl
      self.port = DEFAULT_SSL_PORT if self.port.nil?
    else
      self.port = DEFAULT_PORT if self.port.nil?
    end

    if self.old_server != self.server or self.old_port != self.port or self.old_ssl != self.ssl
      @mailer = Net::IMAP.new( self.server, self.port, self.ssl )
    end

    self.old_server = self.server
    self.old_port = self.port
    self.old_ssl = self.ssl
  end
end
