require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

MBOX_FILE = File.join( RAILS_ROOT, 'public', 'download', 'bd4937b271d8f20c3003489a231b3824943a163f' )

module Pop3SpecHelper
  def setup_pop3( opts = {}, setup_mailer = true )
    @valid_attributes = {
      :email_address => 'test.otherinbox@gmail.com',
      :server => 'pop.gmail.com',
      :username => 'test.otherinbox@gmail.com',
      :password => '0th3r1nb0x', # TODO need to encrypt this
      :ssl => true,
      :port => 995
    }.merge( opts )

    @pop3 = Pop3.new
    @pop3.attributes = @valid_attributes
    @pop3.setup_mailer if setup_mailer
  end

  def setup_mock_mailer_and_time_pop3( opts = {}, setup_mailer = true )
    @mailer = mock( "Net::POP3" )
    Net::POP3.should_receive(:new).once.and_return(@mailer)
    @mailer.should_receive(:enable_ssl).once
    @time = mock("Time")
    Time.stub!(:now).and_return(@time)
    @time.stub!(:to_s).and_return( 'Thu Jan 08 01:22:01 -0500 2009' )
    setup_pop3( opts, setup_mailer )
  end

  def setup_mock_time_pop3( opts = {}, setup_mailer = true )
    @time = mock("Time")
    Time.should_receive(:now).once.and_return(@time)
    @time.should_receive(:to_s).once.and_return( 'Thu Jan 08 01:22:01 -0500 2009' )
    setup_pop3( opts, setup_mailer )
  end

  def remove_file( file )
    if File.exist?( file )
      FileUtils.rm( file )
    end
  end

  def should_have_error_on_attribute( attribute, value = nil, error_num = 1 )
    setup_pop3( { attribute => value }, false )

    @pop3.should_not be_valid
    @pop3.should have(error_num).error_on(attribute)
  end

  def setup_long_variable( value, length )
    return_value = value
    difference = length - value.size + 1
    1.upto( difference ) { return_value += 'a' }

    return_value
  end
end

describe Pop3, "setup mailer" do
  include Pop3SpecHelper

  before(:each) do
    setup_pop3
  end

  it "should setup mailer" do
    @pop3.mailer.class.should == Net::POP3
  end

  it "should set SSL to true" do
    @pop3.mailer.use_ssl?.should be_true
  end

  it "should set SSL to false" do
    @pop3.ssl = false
    @pop3.setup_mailer

    @pop3.mailer.use_ssl?.should be_false
  end

  it "should set default port if not set" do
    setup_pop3( { :port => nil, :ssl => false } )

    @pop3.port.should == Pop3::DEFAULT_PORT
  end

  it "should set default ssl port if not set" do
    setup_pop3( :port => nil )

    @pop3.port.should == Pop3::DEFAULT_SSL_PORT
  end

  it "should keep track of old server" do
    setup_pop3( @valid_attributes, false )
    @pop3.server.should == @valid_attributes[:server]
    @pop3.old_server.should be_nil
    @pop3.setup_mailer

    new_server = "pop.dreamhost.com"
    @pop3.server = new_server
    @pop3.server.should == new_server
    @pop3.old_server.should == @valid_attributes[:server]
    @pop3.setup_mailer

    @pop3.old_server.should == new_server
  end

  it "should keep track of old port" do
    setup_pop3( @valid_attributes, false )
    @pop3.port.should == @valid_attributes[:port]
    @pop3.old_port.should be_nil
    @pop3.setup_mailer

    new_port = 992
    @pop3.port = new_port
    @pop3.port.should == new_port
    @pop3.old_port.should == @valid_attributes[:port]
    @pop3.setup_mailer

    @pop3.old_port.should == new_port
  end

  it "should not create a new Net::POP3 if server or port hasn't been changed" do
    old_mailer = @pop3.mailer
    @pop3.setup_mailer

    old_mailer.should === @pop3.mailer
  end

  it "should create new Net::POP3 object upon server change" do
    old_mailer = @pop3.mailer
    @pop3.server = "pop.dreamhost.com"
    @pop3.setup_mailer

    old_mailer.should_not == @pop3.mailer
  end

  it "should create new Net::POP3 object upon port change" do
    old_mailer = @pop3.mailer
    @pop3.port = 992
    @pop3.setup_mailer

    old_mailer.should_not == @pop3.mailer
  end

end

describe Pop3, "download mail" do
  include Pop3SpecHelper

  before(:each) do
    remove_file( MBOX_FILE )
  end

  after(:all) do
    remove_file( MBOX_FILE )
  end

  it "should not connect due to authentication problem" do
    setup_mock_mailer_and_time_pop3( :username => 'boo' )

    @mailer.should_receive(:start).once.and_raise(Net::POPAuthenticationError)
    result = @pop3.download

    result[:mail_count].should be_nil
    result[:status].should == Pop3::AUTHENTICATION_ERROR_FLAG
  end

  it "should not connect due to invalid server" do
    setup_mock_mailer_and_time_pop3( :server => 'pop.wornpath.net' )

    @mailer.should_receive(:start).once.and_raise(Timeout::Error)
    result = @pop3.download

    result[:mail_count].should be_nil
    result[:status].should == Pop3::TIMEOUT_ERROR_FLAG
  end

  it "should download mail" do
    setup_mock_time_pop3
    result = @pop3.download
    result.should_not be_nil

    result[:mail_count].should === 3
    result[:status].should === Pop3::OK_FLAG
  end
end

describe Pop3, "write mbox" do
  include Pop3SpecHelper

  before(:each) do
    remove_file( MBOX_FILE )
  end

  after(:all) do
    remove_file( MBOX_FILE )
  end

  it "should generate mbox name" do
    setup_mock_time_pop3

    @pop3.generate_mbox_name.should == 'bd4937b271d8f20c3003489a231b3824943a163f'
  end

  it "should generate mbox file" do
    setup_mock_time_pop3
    @pop3.download

    File.should be_exist( MBOX_FILE )
  end
end

describe Pop3, "validations" do
  include Pop3SpecHelper

  it "should create a valid Pop3" do
    setup_pop3( {}, false )

    @pop3.should be_valid
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
    long_email = setup_long_variable( "boo@boo.com", Pop3::MAX_CHAR_LENGTH )
    should_have_error_on_attribute( :email_address, long_email )
  end

  it "should require server to be less than or equal to max chars" do
    long_server = setup_long_variable( "pop.gmail.com", Pop3::MAX_CHAR_LENGTH )
    should_have_error_on_attribute( :server, long_server )
  end

  it "should require username to be less than or equal to max chars" do
    long_username = setup_long_variable( "otherinbox", Pop3::MAX_CHAR_LENGTH )
    should_have_error_on_attribute( :username, long_username )
  end

  it "should require password to be less than or equal to max chars" do
    long_password = setup_long_variable( "password", Pop3::MAX_CHAR_LENGTH )
    should_have_error_on_attribute( :password, long_password )
  end
end
