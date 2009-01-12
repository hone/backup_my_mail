require 'net/pop'

class Pop3 < RemoteMail
  DEFAULT_PORT = 110
  DEFAULT_SSL_PORT = 992

  RemoteMailHelper::setup_columns( self )
  column :old_server, :string
  column :old_port, :integer

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
      mbox_zip = "#{mbox_name}.zip"
      zip_output = "#{FILE_DIR}/#{mbox_name}.zip"
      zip( { "#{TMP_DIR}/#{mbox_name}" => "inbox.mbox" }, zip_output )
      @mailer.finish
    rescue Net::POPAuthenticationError
      status = AUTHENTICATION_ERROR_FLAG
    rescue Timeout::Error
      status = TIMEOUT_ERROR_FLAG
    end

    {
      :mail_count => mail_count,
      :mbox_name => mbox_zip,
      :status => status
    }
  end


  def write_mbox( name )
    filename = "#{TMP_DIR}/#{name}"
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
