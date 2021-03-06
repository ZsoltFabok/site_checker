require 'spec_helper'
require 'site_checker/io/io_spec_helper'

describe "Integration" do
  include IoSpecHelper

  before(:each) do
    SiteChecker.configure do |config|
      config.visit_references = true
    end
  end

  describe "server based checking" do
    before(:each) do
      @test_url = "http://localhost:4000"
      @root = "http://localhost:4000"
    end

    it "should visit the page" do
      content = "<html></html>"
      webmock(@test_url, 200, content)
      SiteChecker.check(@test_url, @root)
      expect(SiteChecker.local_pages).to eql([@test_url])
      expect(SiteChecker.problems).to be_empty
    end

    it "should check the link to an external page" do
      content = "<html>text<a href=\"http://external.org/\"/></html>"
      webmock(@test_url, 200, content)
      webmock("http://external.org", 200, "")
      SiteChecker.check(@test_url, @root)
      expect(SiteChecker.remote_pages.sort).to eql(["http://external.org/" ])
      expect(SiteChecker.problems).to be_empty
    end

    it "should not check the link to an external page if the reference checking is turned off" do
      SiteChecker.configure do |config|
        config.visit_references = false
      end
      content = "<html>text<a href=\"http://external.org/\"/></html>"
      webmock(@test_url, 200, content)
      SiteChecker.check(@test_url, @root)
      expect(SiteChecker.problems).to be_empty
    end

    it "should report a problem if the external link is dead" do
      content = "<html>text<a href=\"http://external.org/\"/></html>"
      webmock(@test_url, 200, content)
      webmock("http://external.org", 404, "")
      SiteChecker.check(@test_url, @root)
      expect(SiteChecker.problems).to eql({@test_url => ["http://external.org/ (404)"]})
    end

    it "should check the link to an external image" do
      content = "<html>text<img src=\"http://external.org/a.png\"/></html>"
      webmock(@test_url, 200, content)
      webmock("http://external.org/a.png", 200, "")
      SiteChecker.check(@test_url, @root)
      expect(SiteChecker.problems).to be_empty
    end

    it "should check the link to a local image" do
      content = "<html>text<img src=\"/a.png\"/></html>"
      webmock(@test_url, 200, content)
      webmock("#{@test_url}/a.png", 200, "")
      SiteChecker.check(@test_url, @root)
      expect(SiteChecker.problems).to be_empty
    end

    it "should report a problem if the image cannot be found" do
      content = "<html>text<img src=\"http://external.org/a.png\"/></html>"
      webmock(@test_url, 200, content)
      webmock("http://external.org/a.png", 404, "")
      SiteChecker.check(@test_url, @root)
      expect(SiteChecker.problems).to eql({@test_url => ["http://external.org/a.png (404)"]})
    end

    it "should report a problem for a local page with absolute path" do
      content = "<html>text<a href=\"#{@test_url}/another\"/></html>"
      webmock(@test_url, 200, content)
      webmock("#{@test_url}/another", 200, "")
      SiteChecker.check(@test_url, @root)
      expect(SiteChecker.problems).to eql({@test_url => ["#{@test_url}/another (absolute path)"]})
    end

    it "should report a problem for a local image with absolute path" do
      content = "<html>text<img src=\"#{@test_url}/a.png\"/></html>"
      webmock("#{@test_url}/a.png", 200, "")
      webmock(@test_url, 200, content)
      SiteChecker.check(@test_url, @root)
      expect(SiteChecker.problems).to eql({@test_url => ["#{@test_url}/a.png (absolute path)"]})
    end

    it "should filter out certain links" do
      SiteChecker.configure do |config|
        config.ignore_list = ["/atom.xml", "/"]
      end
      content = "<html>text<a href=\"/atom.xml\"/><br/><a href=\"/\"/></html>"
      webmock(@test_url, 200, content)
      SiteChecker.check(@test_url, @root)
      expect(SiteChecker.problems).to be_empty
    end

    it "should not report a valid internal anchor" do
      content = "<html><a href=\"#goto\">goto</a>text<a id=\"goto\"></a></html>"
      webmock(@test_url, 200, content)
      SiteChecker.check(@test_url, @root)
      expect(SiteChecker.problems).to be_empty
    end

    it "should report an invalid internal anchor" do
      content = "<html><a href=\"#goto\">goto</a>text<a id=\"got\"></a></html>"
      webmock(@test_url, 200, content)
      SiteChecker.check(@test_url, @root)
      expect(SiteChecker.problems).to eql({@test_url => ["#goto (404 Not Found)"]})
    end

    it "should follow an external anchor to the external page" do
      content = "<html><a href=\"http://example.org#goto\">goto</a></html>"
      webmock(@test_url, 200, content)
      webmock("http://example.org", 200, content)
      SiteChecker.check(@test_url, @root)
      expect(SiteChecker.problems).to be_empty
    end

    it "should go down one level down for an internal page" do
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      webmock(@test_url, 200, content)
      webmock("#{@root}/one-level-down", 200, "<html></html>")
      SiteChecker.check(@test_url, @root)
      expect(SiteChecker.problems).to be_empty
    end

    it "should report a problem with a linked local page" do
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      webmock(@test_url, 200, content)
      webmock("#{@root}/one-level-down", 404, "<html></html>")
      SiteChecker.check(@test_url, @root)
      expect(SiteChecker.problems).to eql({@test_url => ["/one-level-down (404)"]})
    end

    it "should report a problem when the content type is not an html" do
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      webmock(@test_url, 200, content)
      webmock("#{@root}/one-level-down", 200, "<html></html>", {"Content-Type"=>"text/plain; charset=UTF-8"})
      SiteChecker.check(@test_url, @root)
      expect(SiteChecker.problems).to eql({@test_url => ["/one-level-down (not a text/html content-type)"]})
    end
  end

  describe "file system based checking" do
    before(:each) do
      @root = fs_test_path
      clean_fs_test_path
    end

    it "should find a referenced page" do
      @root = fs_test_path
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      filesystemmock("index.html", content)
      filesystemmock("/one-level-down/index.html", content)
      SiteChecker.check(fs_test_path, @root)
      expect(SiteChecker.local_pages.sort).to eql(["/one-level-down", fs_test_path])
      expect(SiteChecker.problems).to be_empty
    end

    it "should report a problem when the local page cannot be found" do
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      filesystemmock("index.html", content)
      SiteChecker.check(fs_test_path, @root)
      expect(SiteChecker.problems).to eql({fs_test_path => ["/one-level-down (404 Not Found)"]})
    end

    it "should use the local images" do
      content = "<html>text<img src=\"/a.png\"/></html>"
      filesystemmock("index.html", content)
      filesystemmock("a.png", "")
      SiteChecker.check(fs_test_path, @root)
      expect(SiteChecker.local_images.sort).to eql(["/a.png"])
      expect(SiteChecker.problems).to be_empty
    end

    it "should report a problem when the local image cannot be found" do
      content = "<html>text<img src=\"/a.png\"/></html>"
      filesystemmock("index.html", content)
      SiteChecker.check(fs_test_path, @root)
      expect(SiteChecker.problems).to eql({fs_test_path => ["/a.png (404 Not Found)"]})
    end

    it "should be able to handle anchors in other files" do
      content = "<html><a href=\"/other#goto\">goto</a>text<a id=\"goto\"></a></html>"
      content2 = "<html><a id=\"goto\">goto</a>"
      filesystemmock("index.html", content)
      filesystemmock("other/index.html", content2)
      SiteChecker.check(fs_test_path, @root)
      expect(SiteChecker.problems).to be_empty
    end
  end

  describe "without root argument" do
    before(:each) do
      @test_url = "http://localhost:4000"
    end

    it "should check the link to an external page" do
      content = "<html>text<a href=\"http://external.org/\"/></html>"
      webmock(@test_url, 200, content)
      webmock("http://external.org", 200, "")
      SiteChecker.check(@test_url)
      expect(SiteChecker.remote_pages.sort).to eql(["http://external.org/" ])
      expect(SiteChecker.problems).to be_empty
    end

    it "should report a problem for a local page with absolute path" do
      content = "<html>text<a href=\"#{@test_url}/another\"/></html>"
      webmock(@test_url, 200, content)
      webmock("#{@test_url}/another", 200, "")
      SiteChecker.check(@test_url)
      expect(SiteChecker.problems).to eql({@test_url => ["#{@test_url}/another (absolute path)"]})
    end

    it "should report a problem when the local image cannot be found" do
      content = "<html>text<img src=\"/a.png\"/></html>"
      filesystemmock("index.html", content)
      SiteChecker.check(fs_test_path)
      expect(SiteChecker.problems).to eql({fs_test_path => ["/a.png (404 Not Found)"]})
    end
  end
end
