require 'spec_helper'

describe SiteChecker::LinkCollector do
  context "#check" do
    before(:each) do
      @test_url = "http://localhost:4000"
      @root = "http://localhost:4000"
      @collector = SiteChecker::LinkCollector.new do |config|
        config.visit_references = true
      end
    end

    it "should check a link only once" do
      content = "<html>text<a href=\"http://external.org/\"/><a href=\"http://external.org/\"/></html>"
      content_reader = double
      expect(@collector).to receive(:get_content_reader).and_return(content_reader)
      localhost = create_link("http://localhost:4000")
      external = create_link("http://external.org/")
      expect(content_reader).to receive(:get).with(localhost).and_return(content)
      expect(content_reader).to receive(:get).with(external)
      @collector.check(@test_url, @root)
    end

    it "should stop recursion when configured depth is reached" do
      @collector = SiteChecker::LinkCollector.new do |config|
        config.max_recursion_depth = 2
      end
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      one_level_down_content = "<html><a href=\"/two-levels-down\"/></html>"
      two_levels_down_content = "<html><a href=\"/three-levels-down\"/></html>"
      three_levels_down_content = "<html></html>"
      content_reader = double
      expect(@collector).to receive(:get_content_reader).and_return(content_reader)
      expect(content_reader).to receive(:get).with(create_link(@test_url)).and_return(content)
      expect(content_reader).to receive(:get).with(create_link("/one-level-down")).and_return(one_level_down_content)
      expect(content_reader).to receive(:get).with(create_link("/two-levels-down")).and_return(two_levels_down_content)
      @collector.check(@test_url, @root)
      expect(@collector.problems).to be_empty
    end

    it "should not visit a local page that does not exist and report is an error" do
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      content_reader = double
      expect(@collector).to receive(:get_content_reader).and_return(content_reader)
      expect(content_reader).to receive(:get).with(create_link(@test_url)).and_return(content)
      expect(content_reader).to receive(:get).with(create_link("/one-level-down")).and_raise(OpenURI::HTTPError.new("404 Not Found", nil))
      @collector.check(@test_url, @root)
      expect(@collector.problems).to eql({@test_url => ["/one-level-down 404 Not Found"]})
    end
  end
end