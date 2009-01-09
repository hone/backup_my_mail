require 'net/pop'
require 'digest/sha1'

class Pop3 < RemoteMail
  DEFAULT_PORT = 110
  DEFAULT_SSL_PORT = 992

#   PORT_MIN = 1
#   PORT_MAX = 65535
#   MAX_CHAR_LENGTH = 50

#   OK_FLAG = :ok
#   AUTHENTICATION_ERROR_FLAG = :authentication_error
#   TIMEOUT_ERROR_FLAG = :timeout_error

#   FILE_DIR = File.join( RAILS_ROOT, 'public/download' )

  column :email_address, :string
  column :server , :string
  column :old_server, :string
  column :username , :string
  column :password , :string
  column :ssl , :boolean
  column :port , :integer
  column :old_port, :integer

  # validations
#   validates_presence_of :email_address
#   validates_presence_of :server
#   validates_presence_of :username
#   validates_presence_of :password
#   validates_numericality_of :port, :greater_than_or_equal_to => PORT_MIN, :less_than_or_equal_to => PORT_MAX
#   validates_format_of :email_address, :with => /^[\w.]+@\w+\.(\w+\.)*\w+$/
#   validates_format_of :server, :with => /^\w+\.\w+\.(\w+\.)*\w+$/
#   validates_length_of :email_address, :maximum => MAX_CHAR_LENGTH
#   validates_length_of :server, :maximum => MAX_CHAR_LENGTH
#   validates_length_of :username, :maximum => MAX_CHAR_LENGTH
#   validates_length_of :password, :maximum => MAX_CHAR_LENGTH

  attr_reader :mailer

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
    mail_count = nil
    mbox_name = nil

    status = OK_FLAG
    begin
      @mailer.start( self.username, self.password )
      mail_count = @mailer.mails.size
      mbox_name = generate_mbox_name
      write_mbox( mbox_name )
      @mailer.finish
    rescue Net::POPAuthenticationError
      status = AUTHENTICATION_ERROR_FLAG
    rescue Timeout::Error
      status = TIMEOUT_ERROR_FLAG
    end

    {
      :mail_count => mail_count,
      :mbox_name => mbox_name,
      :status => status
    }
  end

  # generate hash based of e-mail address and current time
  def generate_mbox_name
    Digest::SHA1.hexdigest( "#{self.email_address}|#{Time.now.to_s}" )
  end

  def write_mbox( name )
    filename = "#{FILE_DIR}/#{name}"
    if File.exist?( filename )
      FileUtils.rm( filename )
    end
    File.open( filename, 'a' ) do |file|
      @mailer.mails.each do |mail|
        mail.pop do |chunk|
          file.write chunk
        end
      end
    end
  end
end
