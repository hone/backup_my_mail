require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Pop3SpecHelper
  def setup_pop3( opts = {}, setup_mailer = true )
    @valid_attributes = valid_pop3_attributes.merge( opts )

    @pop3 = Pop3.new
    @pop3.attributes = @valid_attributes
    @pop3.setup_mailer if setup_mailer
  end

  def setup_mock_mailer_and_time_pop3( opts = {}, setup_mailer = true )
    setup_mock_net_pop3
    @time = mock("Time")
    setup_pop3( opts, setup_mailer )
  end

  def setup_mock_net_pop3
    @mailer = mock( "Net::POP3" )
    Net::POP3.should_receive(:new).once.and_return(@mailer)
    @mailer.should_receive(:enable_ssl).once
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
    remove_file( MBOX_FILE_ZIP )
  end

  after(:all) do
    remove_file( MBOX_FILE_ZIP )
  end

  it "should not connect due to authentication problem" do
    setup_mock_mailer_and_time_pop3( :username => 'boo' )

    @mailer.should_receive(:start).once.and_raise(Net::POPAuthenticationError)
    result = @pop3.download

    result[:mail_count].should be_nil
    result[:mbox_name].should be_nil
    result[:status].should == Pop3::AUTHENTICATION_ERROR_FLAG
  end

  it "should not connect due to invalid server" do
    setup_mock_mailer_and_time_pop3( :server => 'pop.wornpath.net' )

    @mailer.should_receive(:start).once.and_raise(Timeout::Error)
    result = @pop3.download

    result[:mail_count].should be_nil
    result[:mbox_name].should be_nil
    result[:status].should == Pop3::TIMEOUT_ERROR_FLAG
  end

  # TODO not sure why this test fails, but gives tempfile error
  it "should download mail" do
    pending( "this test should be run explicitly" )
    setup_mock_time
    Time.should_receive(:now).once.and_return(@time)
    setup_pop3
    puts "tmpdir: #{Dir::tmpdir}"
    result = @pop3.download
    result.should_not be_nil

    result[:mail_count].should == 3
    result[:mbox_name].should == MBOX_ZIP
    result[:status].should === Pop3::OK_FLAG
    File.should be_exist( MBOX_FILE_ZIP )
  end
end

describe Pop3, "write mbox" do
  include Pop3SpecHelper

  before(:each) do
    remove_dir( TMP_MBOX_FILE )
  end

  after(:all) do
    remove_dir( TMP_MBOX_FILE )
  end


  it "should generate mbox file" do
    setup_pop3
    @pop3.mailer.stub!(:mails).and_return([[1],[2],[3]])
    @pop3.write_mbox( MBOX_NAME )

    File.should be_exist( TMP_MBOX_FILE )
  end

  it "should overwrite (truncate) an existing file of the same name" do
    File.open( TMP_MBOX_FILE, 'w' ) do |file|
      file.puts "delete this line"
    end

    setup_pop3
    @pop3.mailer.stub!(:mails).and_return([[1],[2],[3]])
    @pop3.write_mbox( MBOX_NAME )

    File.should be_exist( TMP_MBOX_FILE )
    File.open( TMP_MBOX_FILE ) do |file|
      /^delete this line/.match( file.readlines.first ).should be_nil
    end
  end
end
