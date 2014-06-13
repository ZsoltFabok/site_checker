require 'spec_helper'

describe SiteChecker::IO::ContentFromFileSystem do
  context "#get" do
    before(:each) do
      @root = "/home/test/web/public"
      @link = SiteChecker::Link.create({:url => "link", :kind => :page, :location => :local})
      @file = double(File)
      @content = double
      @content_reader = SiteChecker::IO::ContentFromFileSystem.new(false, @root)
    end

    it "should return the content of a link using the local index.html" do
      expect(File).to receive(:open).with("#{@root}/#{@link.url}/index.html") {@file}
      expect(@file).to receive(:read) {@content}
      expect(@content_reader.get(@link)).to eql(@content)
    end

    it "should return the content of a link which points to a real .html file" do
      @link.url = "/about.html"
      expect(File).to receive(:open).with("#{@root}/about.html") {@file}
      expect(@file).to receive(:read) {@content}
      expect(@content_reader.get(@link)).to eql(@content)
    end

    it "should return the content of a link with anchor" do
      @link.url = "/about#something"
      expect(File).to receive(:open).with("#{@root}/about/index.html") {@file}
      expect(@file).to receive(:read) {@content}
      expect(@content_reader.get(@link)).to eql(@content)
    end

    it "should raise error if the link is broken" do
      expect(File).to receive(:open).with("#{@root}/#{@link.url}/index.html").and_raise(Errno::ENOENT)
      expect {@content_reader.get(@link)}.to raise_error(RuntimeError, "(404 Not Found)")
    end

    it "should check the existence of a local image" do
      @link.kind = :image
      @link.url = "img/image1"
      expect(File).to receive(:open).with("#{@root}/#{@link.url}") {@file}
      expect(@file).not_to receive(:read)
      @content_reader.get(@link)
    end

    it "should not open a remote reference if opt-out" do
      @link.location = :remote
      expect(File).not_to receive(:open)
      @content_reader.get(@link)
    end

    it "should open a remote reference if opt-in" do
      @content_reader = SiteChecker::IO::ContentFromFileSystem.new(true, @root)
      @link.location = :remote
      @link.url = "http://example.org"
      expect(File).not_to receive(:open)
      expect(@content_reader).to receive(:open)
      @content_reader.get(@link)
    end
  end
end