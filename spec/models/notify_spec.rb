require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Notify do
  before(:each) do
    ActionMailer::Base.delivery_method = :test  
    ActionMailer::Base.perform_deliveries = true  
    ActionMailer::Base.deliveries = []  
  end

  it "should deliver success" do
    Notify.deliver_success( 'test.otherinbox@gmail.com', MBOX_NAME )
    ActionMailer::Base.deliveries.size.should == 1
  end

  it "should deliver authentication problem" do
    Notify.deliver_authentication_problem( 'test.otherinbox@gmail.com' )
    ActionMailer::Base.deliveries.size.should == 1
  end

  it "should deliver timeout problem" do
    Notify.deliver_timeout_problem( 'test.otherinbox@gmail.com' )
    ActionMailer::Base.deliveries.size.should == 1
  end
end
