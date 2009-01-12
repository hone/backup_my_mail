require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module ImapSpecHelper
  def setup_imap( opts = {}, setup_mailer = true )
    @valid_attributes = valid_imap_attributes.merge( opts )

    @imap = Imap.new
    @imap.attributes = @valid_attributes
    @imap.setup_mailer if setup_mailer
  end

  def setup_mock_net_imap 
    @net_imap = mock( "Net::IMAP" )
    # TODO stubbing this overrides should_receive
#     Net::IMAP.stub!(:new).and_return(@net_imap)
  end
end

describe Imap, "setup mailer" do
  include ImapSpecHelper
  
  it "should setup mailer" do
    setup_imap
    @imap.mailer.class.should == Net::IMAP
  end

  it "should set default port if not set" do
    setup_mock_net_imap
    setup_imap( { :port => nil, :ssl => false } )

    @imap.port.should == Imap::DEFAULT_PORT
  end

  it "should set default ssl port if not set" do
    setup_mock_net_imap
    Net::IMAP.should_receive(:new).once.and_return(@net_imap)
    @net_imap.should_receive(:login).once
    setup_imap( { :port => nil, :ssl => true } )

    @imap.port.should == Imap::DEFAULT_SSL_PORT
  end

  it "should keep track of old server" do
    setup_mock_net_imap
    Net::IMAP.should_receive(:new).twice.and_return(@net_imap)
    @net_imap.should_receive(:login).twice
    setup_imap( {}, false )
    @imap.server.should == @valid_attributes[:server]
    @imap.old_server.should be_nil
    @imap.setup_mailer

    new_server = "mail.wornpath.net"
    @imap.server = new_server
    @imap.server.should == new_server
    @imap.old_server.should == @valid_attributes[:server]
    @imap.setup_mailer

    @imap.old_server.should == new_server
  end

  it "should keep track of old port" do
    setup_mock_net_imap
    Net::IMAP.should_receive(:new).twice.and_return(@net_imap)
    @net_imap.should_receive(:login).twice
    setup_imap( {}, false )
    @imap.port.should == @valid_attributes[:port]
    @imap.old_port.should be_nil
    @imap.setup_mailer

    new_port = 992
    @imap.port = new_port
    @imap.port.should == new_port
    @imap.old_port.should == @valid_attributes[:port]
    @imap.setup_mailer

    @imap.old_port.should == new_port
  end

  it "should keep track of old ssl" do
    setup_mock_net_imap
    Net::IMAP.should_receive(:new).twice.and_return(@net_imap)
    @net_imap.should_receive(:login).twice
    setup_imap( {}, false )
    @imap.ssl.should == @valid_attributes[:ssl]
    @imap.old_ssl.should be_nil
    @imap.setup_mailer

    new_ssl = !@valid_attributes[:ssl]
    @imap.ssl= new_ssl
    @imap.ssl.should == new_ssl
    @imap.old_ssl.should == @valid_attributes[:ssl]
    @imap.setup_mailer

    @imap.old_ssl.should == new_ssl
  end

  it "should not create a new Net::IMAP if server or port or ssl hasn't been changed" do
    setup_mock_net_imap
    Net::IMAP.should_receive(:new).once.and_return(@net_imap)
    @net_imap.should_receive(:login).once

    setup_imap
    @imap.setup_mailer
  end

  it "should create a new Net::IMAP object upon server change" do
    setup_mock_net_imap
    Net::IMAP.should_receive(:new).twice.and_return(@net_imap)
    @net_imap.should_receive(:login).twice
    
    setup_imap
    @imap.server = "pop.dreamhost.com"
    @imap.setup_mailer
  end

  it "should create a new Net::IMAP object upon port change" do
    setup_mock_net_imap
    Net::IMAP.should_receive(:new).twice.and_return(@net_imap)
    @net_imap.should_receive(:login).twice

    setup_imap
    @imap.port = 992
    @imap.setup_mailer
  end

  it "should create a new Net::IMAP object upon ssl change" do
    setup_mock_net_imap
    Net::IMAP.should_receive(:new).twice.and_return(@net_imap)
    @net_imap.should_receive(:login).twice

    setup_imap
    @imap.ssl = !@valid_attributes[:ssl]
    @imap.setup_mailer
  end

  it "should raise error on login problem" do
    setup_mock_net_imap
    Net::IMAP.should_receive(:new).once.and_return(@net_imap)
    @net_imap.should_receive(:login).and_raise( Net::IMAP::NoResponseError )

    result = setup_imap
    result.should == RemoteMail::AUTHENTICATION_ERROR_FLAG
  end

  it "should raise error on timeout" do
    setup_mock_net_imap
    Net::IMAP.should_receive(:new).once.and_return(@net_imap)
    @net_imap.should_receive(:login).and_raise( Errno::ETIMEDOUT )

    result = setup_imap
    result.should == RemoteMail::TIMEOUT_ERROR_FLAG
  end
end

describe Imap, "live connections" do
  include ImapSpecHelper

  after(:all) do
    remove_dir( TMP_MBOX_FILE )
  end

  it "should return all folders" do
    setup_imap

    folders = ["INBOX", "INBOX.Drafts", "INBOX.Sent", "INBOX.Trash", "INBOX.old-messages"]
    @imap.folders.collect {|item| item.name }.sort.should == folders.sort
  end

  it "should download mail in a parent folder" do
    setup_imap
    @imap.stub!(:generate_mbox_name).and_return( MBOX_NAME )

    mailbox_folder = Net::IMAP::MailboxList.new( [:Unmarked, :Haschildren], '.', "INBOX" )
    folder = "#{TMP_MBOX_FILE}/#{mailbox_folder.name}"
    mbox = "#{folder}.mbox"
    remove_dir( TMP_MBOX_FILE )
    FileUtils.mkdir( TMP_MBOX_FILE )
    @imap.download_folder( mailbox_folder, @imap.generate_mbox_name ).should == 1
    File.should be_exist( folder )
    File.should be_directory( folder )
    File.should be_exist( mbox )

    remove_file( mbox )
    remove_dir( folder )
  end

  it "should download mail in a leaf folder" do
    setup_imap
    @imap.stub!(:generate_mbox_name).and_return( MBOX_NAME )

    mailbox_folder = Net::IMAP::MailboxList.new( [:Unmarked, :Hasnochildren], '.', "INBOX.Drafts" )
    parent_dir = "#{TMP_MBOX_FILE}/INBOX" 
    mbox = "#{parent_dir}/Drafts.mbox" 

    remove_dir( TMP_MBOX_FILE )
    FileUtils.mkdir( TMP_MBOX_FILE )
    FileUtils.mkdir( parent_dir )
    @imap.download_folder( mailbox_folder, @imap.generate_mbox_name ).should == 1
    File.should be_exist( mbox )
    File.should_not be_exist( "#{parent_dir}/Drafts" )

    remove_file( mbox )
    remove_dir( parent_dir )
  end

  it "should download to a zip for all folders" do
    setup_imap
    @imap.stub!(:generate_mbox_name).and_return( MBOX_NAME )
    remove_file( MBOX_FILE_ZIP )

    @imap.download.should == MBOX_FILE_ZIP
    File.should be_exist( MBOX_FILE_ZIP )
  end
end
