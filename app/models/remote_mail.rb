# interface for accessing RemoteMail
class RemoteMail < ActiveRecord::BaseWithoutTable
  PORT_MIN = 1
  PORT_MAX = 65535
  MAX_CHAR_LENGTH = 50

  OK_FLAG = :ok
  AUTHENTICATION_ERROR_FLAG = :authentication_error
  TIMEOUT_ERROR_FLAG = :timeout_error

  FILE_DIR = File.join( RAILS_ROOT, 'public/download' )

  column :email_address, :string
  column :server , :string
  column :old_server, :string
  column :username , :string
  column :password , :string
  column :ssl , :boolean
  column :port , :integer
  column :old_port, :integer

  # validations
  validates_presence_of :email_address
  validates_presence_of :server
  validates_presence_of :username
  validates_presence_of :password
  validates_numericality_of :port, :greater_than_or_equal_to => PORT_MIN, :less_than_or_equal_to => PORT_MAX
  validates_format_of :email_address, :with => /^[\w.]+@\w+\.(\w+\.)*\w+$/
  validates_format_of :server, :with => /^\w+\.\w+\.(\w+\.)*\w+$/
  validates_length_of :email_address, :maximum => MAX_CHAR_LENGTH
  validates_length_of :server, :maximum => MAX_CHAR_LENGTH
  validates_length_of :username, :maximum => MAX_CHAR_LENGTH
  validates_length_of :password, :maximum => MAX_CHAR_LENGTH

  def download
    raise NotImplementedError.new
  end
end
