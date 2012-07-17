require 'spec_helper'

describe SiteChecker do
  before (:each) do
    @checker = SiteChecker.new do |config|
      config.visit_references = true
    end
  end

  describe "server based checking" do
    before (:each) do
      @test_url = "http://localhost:4000"
      @root = "http://localhost:4000"
    end
    
    it "should visit the page" do
      content = "<html></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.check(@test_url, @root)
      @checker.local_pages.should eql([@test_url])
    end

    it "should check the link to an external page" do
      content = "<html>text<a href=\"http://external.org/\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("http://external.org")
      @checker.check(@test_url, @root)
      @checker.remote_pages.should eql(["http://external.org" ])
    end
    
    it "should not check the link to an external page if the reference checking is turned off" do
      @checker = SiteChecker.new do |config|
        config.visit_references = false
      end
      content = "<html>text<a href=\"http://external.org/\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_not_receive(:open).with("http://external.org")
      @checker.check(@test_url, @root)
    end

    it "should check the link to an external page only once" do
      content = "<html>text<a href=\"http://external.org/\"/><a href=\"http://external.org/\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("http://external.org")
      @checker.check(@test_url, @root)
    end

    it "should report a problem if the external link is dead" do
      content = "<html>text<a href=\"http://external.org/\"/></html>"
      http_error_message = "404 Not Found "
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("http://external.org").and_raise(OpenURI::HTTPError.new(http_error_message, nil))
      @checker.check(@test_url, @root)
      @checker.problems.should eql({@test_url => ["http://external.org (#{http_error_message.strip})"]})
    end

    it "should check the link to an external image" do
      content = "<html>text<img src=\"http://external.org/a.png\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("http://external.org/a.png")
      @checker.check(@test_url, @root)
    end

    it "should check the link to an external image only once" do
      content = "<html>text<img src=\"http://external.org/a.png\"/><img src=\"http://external.org/a.png\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("http://external.org/a.png")
      @checker.check(@test_url, @root)
    end

    it "should check the link to a local image" do
      content = "<html>text<img src=\"/a.png\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("#{@test_url}/a.png")
      @checker.check(@test_url, @root)
    end

    it "should report a problem if the image cannot be found" do
      content = "<html>text<img src=\"http://external.org/a.png\"/></html>"
      http_error_message = "404 Not Found "
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("http://external.org/a.png").and_raise(OpenURI::HTTPError.new(http_error_message, nil))
      @checker.check(@test_url, @root)
    end

    it "should report a problem for a local page with absolute path" do
      content = "<html>text<a href=\"#{@test_url}/another\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_not_receive(:open).with("#{@test_url}/another")
      @checker.check(@test_url, @root)
      @checker.problems.should eql({@test_url => ["#{@test_url}/another (absolute path)"]})
    end

    it "should report a problem for a local image with absolute path" do
      content = "<html>text<img src=\"#{@test_url}/a.png\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_not_receive(:open).with("#{@test_url}/a.png")
      @checker.check(@test_url, @root)
      @checker.problems.should eql({@test_url => ["#{@test_url}/a.png (absolute path)"]})
    end

    it "should filter out certain links" do
      @checker = SiteChecker.new do |config|
        config.ignore_list = ["/atom.xml", "/"]
      end
      content = "<html>text<a href=\"/atom.xml\"/><br/><a href=\"/\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_not_receive(:open).with("#{@test_url}/atom.xml")
      @checker.check(@test_url, @root)
    end
    
    it "should not report a valid internal anchor" do
      content = "<html><a href=\"#goto\">goto</a>text<a id=\"goto\"></a></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.check(@test_url, @root)
      @checker.problems.should be_empty
    end
    
    it "should report an invalid internal anchor" do
      content = "<html><a href=\"#goto\">goto</a>text<a id=\"got\"></a></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.check(@test_url, @root)
      @checker.problems.should eql({@test_url => ["#goto (404 Not Found)"]})
    end

    it "should go down one level down for an internal page" do
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("#{@root}/one-level-down") {"<html></html>"}
      @checker.check(@test_url, @root)
    end

    it "should report a problem with a linked local page" do
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      http_error_message = "404 Not Found "
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("#{@test_url}/one-level-down").and_raise(OpenURI::HTTPError.new(http_error_message, nil))
      @checker.check(@test_url, @root)
      @checker.problems.should eql({@test_url => ["one-level-down (#{http_error_message.strip})"]})
    end

    it "should not visit a page twice" do
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      one_level_down_content = "<html><a href=\"/two-levels-down\"/></html>"
      two_levels_down_content = "<html><a href=\"/one-level-down\"/></html>"
      @checker.should_receive(:open).with(@test_url).once {content}
      @checker.should_receive(:open).with("#{@test_url}/one-level-down") {one_level_down_content}
      @checker.should_receive(:open).with("#{@test_url}/two-levels-down") {two_levels_down_content}
      @checker.check(@test_url, @root)
    end

    it "should ignore the trailing '/' for pages during visitation check" do
      content = "<html>text<a href=\"/one-level-down/\"/></html>"
      one_level_down_content = "<html><a href=\"/two-levels-down\"/></html>"
      two_levels_down_content = "<html><a href=\"/one-level-down\"/></html>"
      @checker.should_receive(:open).with(@test_url).once {content}
      @checker.should_receive(:open).with("#{@test_url}/one-level-down") {one_level_down_content}
      @checker.should_receive(:open).with("#{@test_url}/two-levels-down") {two_levels_down_content}
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
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("#{@test_url}/one-level-down") {one_level_down_content}
      @checker.should_receive(:open).with("#{@test_url}/two-levels-down") {two_levels_down_content}
      @checker.should_not_receive(:open).with("#{@test_url}/three-levels-down")
      @checker.check(@test_url, @root)
    end
  end

  describe "file system based checking" do
    before(:each) do
      @root = "/home/test/web/public"
      @test_path = "/home/test/web/public"
    end

    it "should find a referenced page" do
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      file = mock(File)
      File.should_receive(:open).with("#{@test_path}/index.html") {file}
      file.should_receive(:read).twice {content}
      File.should_receive(:open).with("#{@test_path}/one-level-down/index.html") {file}
      @checker.check(@test_path, @root)
    end
    
    it "should not follow an external reference on page" do
      @checker = SiteChecker.new do |config|
        config.visit_references = false
      end
      content = "<html>text<a href=\"http://example.org\"/></html>"
      file = mock(File)
      File.should_receive(:open).with("#{@test_path}/index.html") {file}
      file.should_receive(:read) {content}
      @checker.should_not_receive(:open).with("http://example.org")
      @checker.check(@test_path, @root)
    end

    it "should report a problem when the local page cannot be found" do
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      http_error_message = "404 Not Found"
      file = mock(File)
      File.should_receive(:open).with("#{@test_path}/index.html") {file}
      file.should_receive(:read) {content}
      File.should_receive(:open).with("#{@test_path}/one-level-down/index.html").and_raise(Errno::ENOENT)
      @checker.check(@test_path, @root)
      @checker.problems.should eql({@test_path => ["one-level-down (#{http_error_message})"]})
    end

    it "should use the local images" do
      content = "<html>text<img src=\"/a.png\"/></html>"
      file = mock(File)
      File.should_receive(:open).with("#{@test_path}/index.html") {file}
      file.should_receive(:read) {content}
      File.should_receive(:open).with("#{@test_path}/a.png")
      @checker.check(@test_path, @root)
    end

    it "should report a problem when the local image cannot be found" do
      content = "<html>text<img src=\"/a.png\"/></html>"
      http_error_message = "404 Not Found"
      file = mock(File)
      File.should_receive(:open).with("#{@test_path}/index.html") {file}
      file.should_receive(:read) {content}
      File.should_receive(:open).with("#{@test_path}/a.png").and_raise(Errno::ENOENT)
      @checker.check(@test_path, @root)
      @checker.problems.should eql({@test_path => ["a.png (#{http_error_message})"]})
    end

    it "should ignore the trailing '/' for pages during visitation check" do
      content = "<html>text<a href=\"/one-level-down/\"/></html>"
      one_level_down_content = "<html><a href=\"/two-levels-down\"/></html>"
      two_levels_down_content = "<html><a href=\"/one-level-down\"/></html>"
      file = mock(File)
      one_level_down_file = mock(File)
      two_levels_down_file = mock(File)
      File.should_receive(:open).with("#{@test_path}/index.html") {file}
      file.should_receive(:read) {content}
      File.should_receive(:open).with("#{@test_path}/one-level-down/index.html") {one_level_down_file}
      one_level_down_file.should_receive(:read).once {one_level_down_content}
      File.should_receive(:open).with("#{@test_path}/two-levels-down/index.html") {two_levels_down_file}
      two_levels_down_file.should_receive(:read) {two_levels_down_content}
      @checker.check(@test_path, @root)
    end

    it "should not extend html pages with index.html" do
      content = "<html>text<a href=\"/about.html\"/></html>"
      file = mock(File)
      File.should_receive(:open).with("#{@test_path}/index.html") {file}
      file.should_receive(:read).twice {content}
      File.should_receive(:open).with("#{@test_path}/about.html") {file}
      @checker.check(@test_path, @root)
    end
  end
end
