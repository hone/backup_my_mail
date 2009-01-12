require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/backups/new" do
  before(:each) do
    @remote_mail = mock_model( RemoteMail )
    valid_pop3_attributes.each do |key, value|
      @remote_mail.stub!(key).and_return( value )
    end
    @remote_mail.stub!(:mail_type).and_return(RemoteMail::POP3)
    assigns[:remote_mail] = @remote_mail
  end
  
  it "should render new form" do
    render 'backups/new'
    response.should have_tag("form[action=?][method=post]", '/backups/create') do
      with_tag( "input#remote_mail_email_address[name=?]", "remote_mail[email_address]" )
      with_tag( "input#remote_mail_server[name=?]", "remote_mail[server]" )
      with_tag( "input#remote_mail_username[name=?]", "remote_mail[username]" )
      with_tag( "input#remote_mail_password[name=?][type=password]", "remote_mail[password]" )
      with_tag( "input#remote_mail_ssl[name=?]", "remote_mail[ssl]" )
      with_tag( "input#remote_mail_port[name=?]", "remote_mail[port]" )
      with_tag( "input#remote_mail_mail_type_1[name=?]", "remote_mail[mail_type]" )
      with_tag( "input[type=submit]" )
    end
  end

  it "should display error notices" do
    @remote_mail = RemoteMail.new
    @remote_mail.save
    assigns[:remote_mail] = @remote_mail
    render 'backups/new'

    response.should have_tag("form[action=?][method=post]", '/backups/create') do
      with_tag( "div[id=errorExplanation]" )
    end
  end
end
