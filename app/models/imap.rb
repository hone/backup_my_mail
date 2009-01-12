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
    status = OK_FLAG

    if self.old_server != self.server or self.old_port != self.port or self.old_ssl != self.ssl
      begin
        @mailer = Net::IMAP.new( self.server, self.port, self.ssl )
        @mailer.login( self.username, self.password )
      rescue Net::IMAP::NoResponseError
        status = AUTHENTICATION_ERROR_FLAG
      rescue Errno::ETIMEDOUT
        status = TIMEOUT_ERROR_FLAG
      end
    end

    self.old_server = self.server
    self.old_port = self.port
    self.old_ssl = self.ssl

    status
  end

  def close
    close
  end

  def folders
    search_folder( '' )
  end

  def download_folder( folder, mbox_name )
    folder_path = "#{TMP_DIR}/#{mbox_name}/#{folder.name.split( folder.delim ).join( "/" )}"
    FileUtils.mkdir( folder_path ) if folder.attr.include?( :Haschildren )
    @mailer.examine( folder.name )
    uids = @mailer.uid_search(['ALL'])
    # if some uids, download data
    if uids.length > 0
      write_mbox( "#{folder_path}.mbox", uids )
    end

    uids.length
  end

  def write_mbox( mbox_name, uids )
    File.open( mbox_name, 'w' ) do |file|
      @mailer.uid_fetch( uids, ['ENVELOPE'] ) do |msg|
        file.puts( source.uid_fetch( msg.attr['UID'], ['RFC822'] ).first.attr['RFC822'] )
      end
    end
  end

  private
  def search_folder( path )
    list = @mailer.list( path, "%" )
    list.inject(Array.new) do |folders, item|
      if item.attr.include?( :Haschildren )
        folders + [item] + search_folder( item.name )
      else
        folders + [item]
      end
    end
  end
end
