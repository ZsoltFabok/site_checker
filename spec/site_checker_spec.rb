require 'spec_helper'

describe SiteChecker do
  before (:each) do
    @checker = SiteChecker.new
    @test_url = "http://localhost:4000"
    @root = "http://localhost:4000"
  end

  describe "page visit" do
    it "should register page visit" do
      content = "<html></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.evaluate_page(@test_url, @root, {:visit_references => true})
      @checker.visited_local_page.should eql([@test_url])
    end

    it "should check the link to an external page" do
      content = "<html>text<a href=\"http://external.org/\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("http://external.org/")
      @checker.evaluate_page(@test_url, @root, {:visit_references => true})
      @checker.visited_external_page.should eql(["http://external.org" ])
    end

    it "should check the link to an external page only once" do
      content = "<html>text<a href=\"http://external.org/\"/><a href=\"http://external.org/\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("http://external.org/")
      @checker.evaluate_page(@test_url, @root, {:visit_references => true})
    end

    it "should report a problem if the external link is dead" do
      content = "<html>text<a href=\"http://external.org/\"/></html>"
      http_error_message = "404 Not Found "
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("http://external.org/").and_raise(OpenURI::HTTPError.new(http_error_message, nil))
      @checker.evaluate_page(@test_url, @root, {:visit_references => true})
      @checker.problems.should eql({@test_url => ["http://external.org/ (#{http_error_message.strip})"]})
    end

    it "should report a problem if the external link is not reachable" do
      content = "<html>text<a href=\"http://external.org/\"/></html>"
      error_message = "unknown host"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("http://external.org/").and_raise(SocketError.new(error_message))
      @checker.evaluate_page(@test_url, @root, {:visit_references => true})
      @checker.problems.should eql({@test_url => ["http://external.org/ (#{error_message})"]})
    end

    it "should check the link to an external image" do
      content = "<html>text<img src=\"http://external.org/a.png\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("http://external.org/a.png")
      @checker.evaluate_page(@test_url, @root, {:visit_references => true})
    end

    it "should check the link to an external image only once" do
      content = "<html>text<img src=\"http://external.org/a.png\"/><img src=\"http://external.org/a.png\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("http://external.org/a.png")
      @checker.evaluate_page(@test_url, @root, {:visit_references => true})
    end

    it "should check the link to a local image" do
      content = "<html>text<img src=\"/a.png\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("#{@test_url}/a.png")
      @checker.evaluate_page(@test_url, @root, {:visit_references => true})
    end

    it "should report a problem if the image cannot be found" do
      content = "<html>text<img src=\"http://external.org/a.png\"/></html>"
      http_error_message = "404 Not Found "
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("http://external.org/a.png").and_raise(OpenURI::HTTPError.new(http_error_message, nil))
      @checker.evaluate_page(@test_url, @root, {:visit_references => true})
    end

    it "should report a problem for a local page with absolute path" do
      content = "<html>text<a href=\"#{@test_url}/another\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_not_receive(:open).with("#{@test_url}/another")
      @checker.evaluate_page(@test_url, @root, {:visit_references => true})
      @checker.problems.should eql({@test_url => ["#{@test_url}/another (absolute path)"]})
    end

    it "should report a problem for a local image with absolute path" do
      content = "<html>text<img src=\"#{@test_url}/a.png\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_not_receive(:open).with("#{@test_url}/a.png")
      @checker.evaluate_page(@test_url, @root, {:visit_references => true})
      @checker.problems.should eql({@test_url => ["#{@test_url}/a.png (absolute path)"]})
    end

    it "should filter out certain links" do
      content = "<html>text<a href=\"/atom.xml\"/><br/><a href=\"/\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_not_receive(:open).with("#{@test_url}/atom.xml")
      @checker.add_filter("/atom.xml")
      @checker.add_filter("/")
      @checker.evaluate_page(@test_url, @root, {:visit_references => true})
    end

    it "should report a problem when a watched url shows up"
    # As far as I remember I needed this for watching hardcoded references when checking remotely
    
    it "should work for this output as well"
    
    # +"http://zsoltfabok.com/blog/2011/05/kanban-on-organisational-level" => ["http://zsoltfabok.com/blog/definitions#waste (404 Not Found)", "http://zsoltfabok.com/blog/tag/XP (404 Not Found)"],
    #           +"http://zsoltfabok.com/blog/2011/07/guest-sensitive-velocity" => ["http://zsoltfabok.com/blog/tag/kaizen (404 Not Found)"],
    #           +"http://zsoltfabok.com/blog/2011/07/reducing-waste-in-testing-1" => ["http://zsoltfabok.com/blog/tag/kaizen (404 Not Found)", "http://zsoltfabok.com/blog/definitions#waste (404 Not Found)"],
    #           +"http://zsoltfabok.com/blog/page/11" => ["http://zsoltfabok.com/blog/tag/kaizen (404 Not Found)", "http://zsoltfabok.com/blog/definitions#waste (404 Not Found)", "http://zsoltfabok.com/blog/tag/kaizen (404 Not Found)"],
    #           +"http://zsoltfabok.com/blog/page/12" => ["http://zsoltfabok.com/blog/definitions#waste (404 Not Found)"]
    #         # ./spec/blog_spec.rb:30:in `block (3 levels) in <top (required)>'
  end

  describe "recursion" do
    it "should go down one level down for an internal page" do
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("#{@root}/one-level-down")
      @checker.evaluate_page(@test_url, @root, {:visit_references => true})
    end

    it "should report a problem with a linked local page" do
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      http_error_message = "404 Not Found "
      @checker.should_receive(:open).with(@test_url) {content}
      @checker.should_receive(:open).with("#{@test_url}/one-level-down").and_raise(OpenURI::HTTPError.new(http_error_message, nil))
      @checker.evaluate_page(@test_url, @root, {:visit_references => true})
      @checker.problems.should eql({@test_url => ["#{@test_url}/one-level-down (#{http_error_message.strip})"]})
    end

    it "should not visit a page twice" do
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      one_level_down_content = "<html><a href=\"/two-levels-down\"/></html>"
      two_levels_down_content = "<html><a href=\"/one-level-down\"/></html>"
      @checker.should_receive(:open).with(@test_url).once {content}
      @checker.should_receive(:open).with("#{@test_url}/one-level-down") {one_level_down_content}
      @checker.should_receive(:open).with("#{@test_url}/two-levels-down") {two_levels_down_content}
      @checker.evaluate_page(@test_url, @root, {:visit_references => true})
    end

    it "should ignore the trailing '/' for pages during visitation check" do
      content = "<html>text<a href=\"/one-level-down/\"/></html>"
      one_level_down_content = "<html><a href=\"/two-levels-down\"/></html>"
      two_levels_down_content = "<html><a href=\"/one-level-down\"/></html>"
      @checker.should_receive(:open).with(@test_url).once {content}
      @checker.should_receive(:open).with("#{@test_url}/one-level-down") {one_level_down_content}
      @checker.should_receive(:open).with("#{@test_url}/two-levels-down") {two_levels_down_content}
      @checker.evaluate_page(@test_url, @root, {:visit_references => true})
    end
    
    it "level of recursion"
  end

  describe "local page" do
    before(:each) do
      @root = "/home/test/web/public"
      @test_path = "/home/test/web/public"
    end

    it "should find a referenced page on the file system" do
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      file = mock(File)
      File.should_receive(:open).with("#{@test_path}/index.html") {file}
      file.should_receive(:read).twice {content}
      File.should_receive(:open).with("#{@test_path}/one-level-down/index.html") {file}
      @checker.evaluate_page(@test_path, @root, {:visit_references => true})
    end

    it "should report a problem when the local page cannot be found" do
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      http_error_message = "404 Not Found"
      file = mock(File)
      File.should_receive(:open).with("#{@test_path}/index.html") {file}
      file.should_receive(:read) {content}
      File.should_receive(:open).with("#{@test_path}/one-level-down/index.html").and_raise(Errno::ENOENT)
      @checker.evaluate_page(@test_path, @root, {:visit_references => true})
      @checker.problems.should eql({@test_path => ["#{@test_path}/one-level-down/index.html (#{http_error_message})"]})
    end

    it "should use the local images" do
      content = "<html>text<img src=\"/a.png\"/></html>"
      file = mock(File)
      File.should_receive(:open).with("#{@test_path}/index.html") {file}
      file.should_receive(:read) {content}
      File.should_receive(:open).with("#{@test_path}/a.png")
      @checker.evaluate_page(@test_path, @root, {:visit_references => true})
    end

    it "should report a problem when the local image cannot be found" do
      content = "<html>text<img src=\"/a.png\"/></html>"
      http_error_message = "404 Not Found"
      file = mock(File)
      File.should_receive(:open).with("#{@test_path}/index.html") {file}
      file.should_receive(:read) {content}
      File.should_receive(:open).with("#{@test_path}/a.png").and_raise(Errno::ENOENT)
      @checker.evaluate_page(@test_path, @root, {:visit_references => true})
      @checker.problems.should eql({@test_path => ["#{@test_path}/a.png (#{http_error_message})"]})
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
      @checker.evaluate_page(@test_path, @root, {:visit_references => true})
    end

    it "should not extend html pages with index.html" do
      content = "<html>text<a href=\"/about.html\"/></html>"
      file = mock(File)
      File.should_receive(:open).with("#{@test_path}/index.html") {file}
      file.should_receive(:read).twice {content}
      File.should_receive(:open).with("#{@test_path}/about.html") {file}
      @checker.evaluate_page(@test_path, @root, {:visit_references => true})
    end
  end
end
