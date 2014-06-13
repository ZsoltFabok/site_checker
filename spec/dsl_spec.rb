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

    local_pages   = double
    local_images  = double
    remote_pages  = double
    remote_images = double
    problems      = double

    expect(SiteChecker).to receive(:check).with(@test_url, @root)
    expect(SiteChecker).to receive(:local_pages).and_return(local_pages)
    expect(SiteChecker).to receive(:remote_pages).and_return(remote_pages)
    expect(SiteChecker).to receive(:local_images).and_return(local_images)
    expect(SiteChecker).to receive(:remote_images).and_return(remote_images)
    expect(SiteChecker).to receive(:problems).and_return(problems)

    check_site(@test_url, @root)
    expect(collected_local_pages).to eql(local_pages)
    expect(collected_remote_pages).to eql(remote_pages)
    expect(collected_local_images).to eql(local_images)
    expect(collected_remote_images).to eql(remote_images)
    expect(collected_problems).to eql(problems)
  end
end