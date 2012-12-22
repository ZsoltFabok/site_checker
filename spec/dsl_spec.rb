require 'spec_helper'
require 'site_checker/io/io_spec_helper'

describe "DSL" do
  include IoSpecHelper

  before(:each) do
    @test_url = "http://localhost:4000"
    @root = "http://localhost:4000"
  end

  it "should forward all the method calls if DSL is enabled" do
     SiteChecker.configure do |config|
      config.dsl_enabled = true
    end

    local_pages   = mock()
    local_images  = mock()
    remote_pages  = mock()
    remote_images = mock()
    problems      = mock()

    SiteChecker.should_receive(:check).with(@test_url, @root)
    SiteChecker.should_receive(:local_pages).and_return(local_pages)
    SiteChecker.should_receive(:remote_pages).and_return(remote_pages)
    SiteChecker.should_receive(:local_images).and_return(local_images)
    SiteChecker.should_receive(:remote_images).and_return(remote_images)
    SiteChecker.should_receive(:problems).and_return(problems)

    check_site(@test_url, @root)
    collected_local_pages.should eql(local_pages)
    collected_remote_pages.should eql(remote_pages)
    collected_local_images.should eql(local_images)
    collected_remote_images.should eql(remote_images)
    collected_problems.should eql(problems)
  end
end