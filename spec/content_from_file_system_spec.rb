require 'spec_helper'

describe ContentFromFileSystem do
  context "#get" do
    before(:each) do
      @root = "/home/test/web/public"
      @link = Link.create({:url => "link", :kind => :page, :location => :local})
      @file = mock(File)
      @content = mock()
      @content_reader = ContentFromFileSystem.new(false, @root)
    end

    it "should return the content of a link using the local index.html" do
      File.should_receive(:open).with("#{@root}/#{@link.url}/index.html") {@file}
      @file.should_receive(:read) {@content}
      @content_reader.get(@link).should eql(@content)
    end

    it "should return the content of a link which points to a real .html file" do
      @link.url = "/about.html"
      File.should_receive(:open).with("#{@root}/about.html") {@file}
      @file.should_receive(:read) {@content}
      @content_reader.get(@link).should eql(@content)
    end

    it "should return the content of a link with anchor" do
      @link.url = "/about#something"
      File.should_receive(:open).with("#{@root}/about/index.html") {@file}
      @file.should_receive(:read) {@content}
      @content_reader.get(@link).should eql(@content)
    end

    it "should raise error if the link is broken" do
      File.should_receive(:open).with("#{@root}/#{@link.url}/index.html").and_raise(Errno::ENOENT)
      expect {@content_reader.get(@link)}.to raise_error(RuntimeError, "(404 Not Found)")
    end

    it "should check the existence of a local image" do
      @link.kind = :image
      @link.url = "img/image1"
      File.should_receive(:open).with("#{@root}/#{@link.url}") {@file}
      @file.should_not_receive(:read)
      @content_reader.get(@link).should
    end

    it "should not open a remote reference if opt-out" do
      @link.location = :remote
      File.should_not_receive(:open)
      @content_reader.get(@link)
    end

    it "should open a remote reference if opt-in" do
      @content_reader = ContentFromFileSystem.new(true, @root)
      @link.location = :remote
      @link.url = "http://example.org"
      File.should_not_receive(:open)
      @content_reader.should_receive(:open)
      @content_reader.get(@link)
    end
  end
end