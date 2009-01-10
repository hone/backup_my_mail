require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module BackupsControllerSpecHelper
  def setup_create( result )
    Pop3.should_receive(:new).once.and_return(@pop3)
    @pop3.should_receive(:valid?).once.and_return(true)
    @pop3.should_receive(:setup_mailer).once
    @pop3.should_receive(:download).once.and_return( result )
  end
end

describe BackupsController do

  #Delete these examples and add some real ones
  it "should use BackupsController" do
    controller.should be_an_instance_of(BackupsController)
  end


  describe "GET 'new'" do
    before(:each) do
      @remote_mail = mock_model( RemoteMail )
      RemoteMail.stub!(:new).and_return(@remote_mail)
    end

    it "should be successful" do
      RemoteMail.should_receive(:new).once.and_return(@remote_mail)
      get 'new'
      response.should be_success
      response.should render_template( :new )
    end
  end

  describe "GET 'show'" do
    before(:each) do
      @params = MBOX_NAME
    end

    def do_get
      get :show, :mbox => @params
    end

    it "should be successful" do
      FileUtils.touch( MBOX_FILE )
      do_get

      assigns[:download].should == MBOX_NAME
      response.should be_success
      response.should render_template( :show )

      remove_file( MBOX_FILE )
    end

    it "should redirect if no mbox is specified" do
      @params = nil
      do_get

      response.should redirect_to( :action => :new )
      flash[:notice].should match /no valid mbox/i
    end

    it "should redirect if mbox does not exist" do
      remove_file( MBOX_FILE )
      do_get

      assigns[:download].should == MBOX_NAME
      response.should redirect_to( :action => :new )
      flash[:notice].should match /no valid mbox/i
    end
  end
end

describe BackupsController, " handling POST /backups" do
  include BackupsControllerSpecHelper

  before do
    @pop3 = mock_model( Pop3 )
    Pop3.stub!(:new).and_return(@pop3)
    @pop3.stub!(:valid).and_return(true)
    @params = {
      :email_address => 'test.otherinbox@gmail.com',
      :server => 'pop.gmail.com',
      :username => 'test.otherinbox@gmail.com',
      :password => '0th3r1nb0x', # TODO need to encrypt this
      :ssl => true,
      :port => 995
    }
  end

  def do_post
    post :create, :remote_mail => @params
  end

  it "should redirect to page to download mbox" do
    result =
    {
      :mail_count => 3,
      :mbox_name => MBOX_NAME,
      :status => Pop3::OK_FLAG
    }
    setup_create( result )
    @pop3.should_receive(:email_address).and_return(@params[:email_address])

    do_post
    response.should redirect_to( :action => :show, :mbox => result[:mbox_name] )
    flash[:notice].should match /success/i
  end

  it "should render new page if invalid RemoteMail" do
    @params = nil
    @pop3.should_receive(:valid?).once.and_return(false)

    do_post
    response.should be_success
    response.should render_template( :new )
    flash[:notice].should match /problems/i
  end

  it "should show error for authentication problem" do
    result = 
    {
      :status => Pop3::AUTHENTICATION_ERROR_FLAG
    }
    setup_create( result )

    do_post
    response.should be_success
    response.should render_template(:new)
    flash[:notice].should match /authentication/i
  end

  it "should show error for timeout problem" do
    result = 
    {
      :status => Pop3::TIMEOUT_ERROR_FLAG
    }
    setup_create( result )

    do_post
    response.should be_success
    response.should render_template(:new)
    flash[:notice].should match /timeout/i
  end
end
