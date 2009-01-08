require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

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

  def setup_mock_pop3( opts = {}, setup_mailer = true )
    Net::POP3.should_receive(:new).once.and_return(@mailer)
    @mailer.should_receive(:enable_ssl).once
    setup_pop3( opts, setup_mailer )
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

  it "should kepe track of old port" do
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
    @mailer = mock( "Net::POP3" )
  end

  it "should not connect due to authentication problem after downloading mail" do
    setup_pop3

    result = @pop3.download
    result[:mails].should_not be_nil
    result[:status].should == Pop3::OK_FLAG

    @pop3.mailer.should_receive(:start).once.and_raise(Net::POPAuthenticationError)
    result = @pop3.download

    result[:mails].should be_nil
    result[:status].should == Pop3::AUTHENTICATION_ERROR_FLAG
  end

  it "should not connect due to authentication problem" do
    setup_mock_pop3( :username => 'boo' )

    @mailer.should_receive(:start).once.and_raise(Net::POPAuthenticationError)
    result = @pop3.download

    result[:mails].should be_nil
    result[:status].should == Pop3::AUTHENTICATION_ERROR_FLAG
  end

  it "should not connect due to invalid server" do
    setup_mock_pop3( :server => 'pop.wornpath.net' )

    @mailer.should_receive(:start).once.and_raise(Timeout::Error)
    result = @pop3.download

    result[:mails].should be_nil
    result[:status].should == Pop3::TIMEOUT_ERROR_FLAG
  end

  it "should download mail" do
    setup_pop3
    result = @pop3.download
    @pop3.mails.size.should == 3
    result.should_not be_nil

    result[:mails].should === @pop3.mails
    result[:status].should === Pop3::OK_FLAG
  end
end

describe Pop3, "validations" do
end
