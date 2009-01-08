require 'net/pop'

class Pop3 < ActiveRecord::BaseWithoutTable
  DEFAULT_PORT = 110
  DEFAULT_SSL_PORT = 992

  column :email_address, :string
  column :server , :string
  column :old_server, :string
  column :username , :string
  column :password , :string
  column :ssl , :boolean
  column :port , :integer
  column :old_port, :integer

  attr_reader :mailer

  # callbacks don't seem to be working
#   before_save :setup_mailer

  def setup_mailer
    if self.ssl
      self.port = DEFAULT_SSL_PORT if self.port.nil?
    else
      self.port = DEFAULT_PORT if self.port.nil?
    end

    if old_server != server or old_port != port
      @mailer = Net::POP3.new( self.server, self.port )
    end

    if self.ssl
      @mailer.enable_ssl
    else
      @mailer.disable_ssl
    end

    # keep track of old server and port
    self.old_server = self.server
    self.old_port = self.port
  end
end
