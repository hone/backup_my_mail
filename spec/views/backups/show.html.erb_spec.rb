require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/backups/show" do
  before(:each) do
    assigns[:downloads] = { :inbox => MBOX_NAME }
    render 'backups/show'
  end
  
  it "should show download link" do
    response.should have_tag( "a[href=?]", "/download/#{MBOX_NAME}", "inbox" )
  end
end