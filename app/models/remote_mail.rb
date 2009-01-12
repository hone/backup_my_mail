require 'zip/zip'
require 'zip/zipfilesystem'
require 'digest/sha1'

module RemoteMailHelper
  def self.setup_columns( klass )
    klass.class_eval do
      column :email_address, :string
      column :server , :string
      column :username , :string
      column :password , :string
      column :ssl , :boolean
      column :port , :integer
    end
  end
end

# interface for accessing RemoteMail
class RemoteMail < ActiveRecord::BaseWithoutTable
  PORT_MIN = 1
  PORT_MAX = 65535
  MAX_CHAR_LENGTH = 50
  POP3 = 1
  IMAP = 2

  OK_FLAG = :ok
  AUTHENTICATION_ERROR_FLAG = :authentication_error
  TIMEOUT_ERROR_FLAG = :timeout_error

  FILE_DIR = File.join( RAILS_ROOT, 'public', 'download' )
  TMP_DIR = File.join( RAILS_ROOT, 'public', 'tmp' )

  RemoteMailHelper::setup_columns( self )
  column :mail_type, :integer

  # validations
  validates_presence_of :email_address
  validates_presence_of :server
  validates_presence_of :username
  validates_presence_of :password
  validates_presence_of :mail_type
  validates_numericality_of :port, :greater_than_or_equal_to => PORT_MIN, :less_than_or_equal_to => PORT_MAX, :allow_nil => true, :only_integer => true
  validates_numericality_of :mail_type, :greater_than_or_equal_to => 1, :less_than_or_equal_to => 2, :only_integer => true
  validates_format_of :email_address, :with => /^[\w.]+@\w+\.(\w+\.)*\w+$/
  validates_format_of :server, :with => /^\w+\.\w+\.(\w+\.)*\w+$/
  validates_length_of :email_address, :maximum => MAX_CHAR_LENGTH
  validates_length_of :server, :maximum => MAX_CHAR_LENGTH
  validates_length_of :username, :maximum => MAX_CHAR_LENGTH
  validates_length_of :password, :maximum => MAX_CHAR_LENGTH

  def download
    raise NotImplementedError.new
  end
  
  # generate hash based of e-mail address and current time
  def generate_mbox_name
    Digest::SHA1.hexdigest( "#{self.email_address}|#{Time.now.to_s}" )
  end

  def zip( files, output_file )
    if File.exist?( output_file )
      FileUtils.rm( output_file )
    end
    Zip::ZipFile.open(output_file, Zip::ZipFile::CREATE) do |zipfile|
      files.each do |source, destination|
        base_file = File.basename( source )
        zipfile.add( destination, source )
      end
    end

    files.keys.each {|file| remove_file_dir( file ) }
  end

  def remove_file_dir( path )
    if File.exist?( path )
      if File.directory?( path )
        Dir[ "#{path}/*" ].each do |file|
          remove_file_dir( file )
        end

        FileUtils.rmdir( path )
      else
        FileUtils.rm( path )
      end
    end
  end
end
