require 'spec_helper'
require_relative 'io_spec_helper'

describe SiteChecker::IO::ContentFromWeb do
  include IoSpecHelper
  context "#get" do
    before(:each) do
      @root = "http://localhost:4000"
      @link = SiteChecker::Link.create({:url => "link", :kind => :page, :location => :local})
      @content = double
      @content_reader = SiteChecker::IO::ContentFromWeb.new(false, @root)
    end

    it "should return the content of a link" do
      expect(@content).to receive(:meta).and_return({"content-type"=>"text/html; charset=UTF-8"})
      expect(@content_reader).to receive(:open).with(URI("#{@root}/#{@link.url}")).and_return(@content)
      expect(@content_reader.get(@link)).to eql(@content)
    end

    it "should raise error if the link is broken" do
      expect(@content_reader).to receive(:open).with(URI("#{@root}/#{@link.url}")).
        and_raise(OpenURI::HTTPError.new("404 Not Found", nil))
      expect {@content_reader.get(@link)}.to raise_error(RuntimeError, "(404 Not Found)")
    end

    it "should check the existence of an image" do
      @link.kind = :image
      @link.url = "img/image1"
      expect(@content_reader).to receive(:open).with(URI("#{@root}/#{@link.url}"))
      @content_reader.get(@link)
    end

    it "should not open a remote reference if opt-out" do
      @link.location = :remote
      expect(@content_reader).not_to receive(:open).with(URI("#{@root}/#{@link.url}"))
      @content_reader.get(@link)
    end

    it "should open a remote reference if opt-in" do
      @content_reader = SiteChecker::IO::ContentFromWeb.new(true, @root)
      @link.location = :remote
      @link.url = "http://example.org"
      expect(@content_reader).to receive(:open).with(URI(@link.url))
      @content_reader.get(@link)
    end
  end
end