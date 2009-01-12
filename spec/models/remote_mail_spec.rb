require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module RemoteMailSpecHelper
  def setup_remote_mail( options = {} )
    @remote_mail = RemoteMail.new
    @remote_mail.attributes = valid_pop3_attributes.merge( options )
  end

  def should_have_error_on_attribute( attribute, value = nil, error_num = 1 )
    setup_remote_mail( { attribute => value } )

    @remote_mail.should_not be_valid
    @remote_mail.should have(error_num).error_on(attribute)
  end
end

describe RemoteMail do
  include RemoteMailSpecHelper

  it "should generate mbox name" do
    setup_mock_time
    setup_remote_mail

    @remote_mail.generate_mbox_name.should == 'bd4937b271d8f20c3003489a231b3824943a163f'
  end
end

describe RemoteMail, "zip" do
  include RemoteMailSpecHelper
  
  before(:all) do
    @zip_output = MBOX_FILE_ZIP
  end

  before(:each) do
    setup_remote_mail
    FileUtils.touch( TMP_MBOX_FILE )
  end

  it "should zip a single mbox" do
    @remote_mail.zip( [TMP_MBOX_FILE], @zip_output )
    File.should be_exist( @zip_output )
    File.should_not be_exist( TMP_MBOX_FILE )
  end
  
  it "should overwrite existing zip file" do
    remove_file( @zip_output )
    File.open( @zip_output, 'w' ) {|file| file.puts "delete this" }

    @remote_mail.zip( [TMP_MBOX_FILE], @zip_output )
    File.should be_exist( @zip_output )
    File.open( @zip_output ) {|file| file.readlines.first.should_not match /delete this/ }
  end

  after(:all) do
    remove_file( TMP_MBOX_FILE )
    remove_file( @zip_output )
  end
end

describe RemoteMail, "validations" do
  include RemoteMailSpecHelper

  it "should create a valid RemoteMail" do
    setup_remote_mail

    @remote_mail.should be_valid
  end

  it "should require an email address" do
    should_have_error_on_attribute( :email_address, nil, 3 )
  end

  it "should require a server" do
    should_have_error_on_attribute( :server, nil, 3 )
  end

  it "should require a username" do
    should_have_error_on_attribute( :username, nil, 2 )
  end

  it "should require a password" do
    should_have_error_on_attribute( :password, nil, 2 )
  end

  it "should require port to be greater than or equal to port min" do
    should_have_error_on_attribute( :port, Pop3::PORT_MIN - 1 )
  end

  it "should require port to be less than or equal to port max" do
    should_have_error_on_attribute( :port, Pop3::PORT_MAX + 1 )
  end

  it "should require a somewhat valid email address" do
    should_have_error_on_attribute( :email_address, 'boo' )
    should_have_error_on_attribute( :email_address, 'boo@boo.boo.' )
  end

  it "should require a somewhat valid server" do
    should_have_error_on_attribute( :server, 'boo' )
    should_have_error_on_attribute( :server, 'boo.boo' )
    should_have_error_on_attribute( :server, 'boo.boo.boo.' )
  end

  it "should require email address to be less than or equal to max chars" do
    long_email = setup_long_variable( "boo@boo.com", RemoteMail::MAX_CHAR_LENGTH )
    should_have_error_on_attribute( :email_address, long_email )
  end

  it "should require server to be less than or equal to max chars" do
    long_server = setup_long_variable( "pop.gmail.com", RemoteMail::MAX_CHAR_LENGTH )
    should_have_error_on_attribute( :server, long_server )
  end

  it "should require username to be less than or equal to max chars" do
    long_username = setup_long_variable( "otherinbox", RemoteMail::MAX_CHAR_LENGTH )
    should_have_error_on_attribute( :username, long_username )
  end

  it "should require password to be less than or equal to max chars" do
    long_password = setup_long_variable( "password", RemoteMail::MAX_CHAR_LENGTH )
    should_have_error_on_attribute( :password, long_password )
  end
end
