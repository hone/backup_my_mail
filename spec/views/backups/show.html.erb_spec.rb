require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/backups/show" do
  before(:each) do
    assigns[:download] = MBOX_NAME
    render 'backups/show'
  end
  
  it "should show thank you" do
    response.should have_text( /thank you/i )
  end
end
