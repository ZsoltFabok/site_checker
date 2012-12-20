require 'spec_helper'

describe SiteChecker do
	context "#check" do
	  before(:each) do
	  	@test_url = "http://localhost:4000"
	  	@root = "http://localhost:4000"
	    @checker = SiteChecker.new do |config|
	      config.visit_references = true
	    end
	  end

    it "should check a link only once" do
      content = "<html>text<a href=\"http://external.org/\"/><a href=\"http://external.org/\"/></html>"
      content_reader = mock()
      @checker.should_receive(:get_content_reader).and_return(content_reader)
      localhost = Link.create({:url => "http://localhost:4000"})
      external = Link.create({:url => "http://external.org/"})
      content_reader.should_receive(:get).with(localhost).and_return(content)
      content_reader.should_receive(:get).with(external)
      @checker.check(@test_url, @root)
    end

    it "should stop recursion when configured depth is reached" do
      @checker = SiteChecker.new do |config|
        config.max_recursion_depth = 2
      end
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      one_level_down_content = "<html><a href=\"/two-levels-down\"/></html>"
      two_levels_down_content = "<html><a href=\"/three-levels-down\"/></html>"
      three_levels_down_content = "<html></html>"
      webmock(@test_url, 200, content)
      webmock("#{@test_url}/one-level-down", 200, one_level_down_content)
      webmock("#{@test_url}/two-levels-down", 200, two_levels_down_content)
      @checker.check(@test_url, @root)
      @checker.problems.should be_empty
    end
	end
end