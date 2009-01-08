require 'net/pop'

class Pop3 < ActiveRecord::BaseWithoutTable
  DEFAULT_PORT = 110
  DEFAULT_SSL_PORT = 992

  OK_FLAG = :ok
  AUTHENTICATION_ERROR_FLAG = :authentication_error
  TIMEOUT_ERROR_FLAG = :timeout_error

  column :email_address, :string
  column :server , :string
  column :old_server, :string
  column :username , :string
  column :password , :string
  column :ssl , :boolean
  column :port , :integer
  column :old_port, :integer

  attr_reader :mailer, :mails

  # callbacks don't seem to be working
#   before_save :setup_mailer

  # sets up the Net::POP3 object
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

  def download
    # reset mail info
    @mails = nil

    status = OK_FLAG
    begin
      @mailer.start( self.username, self.password )
      @mails = @mailer.mails
      @mailer.finish
    rescue Net::POPAuthenticationError
      status = AUTHENTICATION_ERROR_FLAG
    rescue Timeout::Error
      status = TIMEOUT_ERROR_FLAG
    end

    { :mails => @mails, :status => status }
  end
end
