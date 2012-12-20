require 'spec_helper'

describe ContentFromWeb do
	context "#get" do
		before(:each) do
			@root = "http://localhost:4000"
			@link = Link.create({:url => "link", :kind => :page, :location => :local})
			@content = mock()
			@content_reader = ContentFromWeb.new(false, @root)
		end

		it "should return the content of a link" do
      @content_reader.should_receive(:open).with(URI("#{@root}/#{@link.url}")).and_return(@content)
      @content_reader.get(@link).should eql(@content)
		end

		it "should raise error if the link is broken" do
			@content_reader.should_receive(:open).with(URI("#{@root}/#{@link.url}")).
				and_raise(OpenURI::HTTPError.new("404 Not Found", nil))
      expect {@content_reader.get(@link)}.to raise_error(RuntimeError, "(404 Not Found)")
		end

		it "should check the existence of an image" do
			@link.kind = :image
			@link.url = "img/image1"
			@content_reader.should_receive(:open).with(URI("#{@root}/#{@link.url}"))
			@content_reader.get(@link)
		end

		it "should not open a remote reference if opt-out" do
			@link.location = :remote
      @content_reader.should_not_receive(:open).with(URI("#{@root}/#{@link.url}"))
      @content_reader.get(@link)
		end

		it "should open a remote reference if opt-in" do
			@content_reader = ContentFromWeb.new(true, @root)
			@link.location = :remote
			@link.url = "http://example.org"
      @content_reader.should_receive(:open).with(URI(@link.url))
      @content_reader.get(@link)
		end
	end
end