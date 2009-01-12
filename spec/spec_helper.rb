# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec'
require 'spec/rails'

Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  # 
  # For more information take a look at Spec::Example::Configuration and Spec::Runner
end

MBOX_NAME = 'bd4937b271d8f20c3003489a231b3824943a163f'
MBOX_ZIP = "#{MBOX_NAME}.zip"
MBOX_FILE = File.join( RAILS_ROOT, 'public', 'download', MBOX_NAME )
MBOX_FILE_ZIP = File.join( RAILS_ROOT, 'public', 'download', "#{MBOX_NAME}.zip" )
TMP_MBOX_FILE = File.join( RAILS_ROOT, 'public', 'tmp', MBOX_NAME )

def remove_file( file )
  if File.exist?( file )
    FileUtils.rm( file )
  end
end

def setup_mock_time
  @time = mock("Time")
  Time.stub!(:now).and_return(@time)
  @time.stub!(:to_s).and_return( 'Thu Jan 08 01:22:01 -0500 2009' )
end

def valid_pop3_attributes
  @valid_attributes = {
    :email_address => 'test.otherinbox@gmail.com',
    :server => 'pop.gmail.com',
    :username => 'test.otherinbox@gmail.com',
    :password => '0th3r1nb0x', # TODO need to encrypt this
    :ssl => true,
    :port => 995
  }
end

def valid_imap_attributes
  @valid_attributes = {
    :email_address => 'otherinbox@hone.wornpath.net',
    :server => 'mail.hone.wornpath.net',
    :username => 'otherinbox@hone.wornpath.net',
    :password => '0th3r1nb0x', # TODO need to encrypt this
    :ssl => false,
    :port => 143
  }
end

def setup_long_variable( value, length )
  return_value = value
  difference = length - value.size + 1
  1.upto( difference ) { return_value += 'a' }

  return_value
end

def setup_mock_time
  @time = mock("Time")
  Time.should_receive(:now).once.and_return(@time)
  @time.should_receive(:to_s).once.and_return( 'Thu Jan 08 01:22:01 -0500 2009' )
end

def remove_dir( path )
  if File.exist?( path )
    if File.directory?( path )
      Dir[ "#{path}/*" ].each do |file|
        remove_dir( file )
      end

      FileUtils.rmdir( path )
    else
      FileUtils.rm( path )
    end
  end
end
