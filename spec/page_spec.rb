require 'spec_helper'

describe Page do
	context "#parse" do
		before(:each) do
			@root = "http://localhost:4000"
		end

		it "should return the containing local links" do
			content = "<html><a href=\"link1\">link</a>text<a href=\"link2\">link</a></html>"
			links = Page.parse(content, [], @root)
			links.should eql([Link.create({:url => "link1"}), Link.create({:url => "link2"})])
			assert_link(links[0], :page, :local, false)
			assert_link(links[1], :page, :local, false)
		end

		it "should return the containing local images" do
			content = "<html><img src=\"image1\"></img>link</a>text<img src=\"image2\"></img></html>"
			links = Page.parse(content, [], @root)
			links.should eql([Link.create({:url => "image1"}), Link.create({:url => "image2"})])
			assert_link(links[0], :image, :local, false)
			assert_link(links[1], :image, :local, false)
		end

		it "should return an anchor" do
			content = "<html><a href=\"#goto\">link</a>text<a id=\"goto\"></a></html>"
			links = Page.parse(content, [], @root)
			links.should eql([Link.create({:url => "#goto"})])
			assert_link(links[0], :anchor, :local, false)
		end

		it "should mark an anchor which refers to a non existing reference" do
			content = "<html><a href=\"#goto\">link</a></html>"
			links = Page.parse(content, [], @root)
			links.should eql([Link.create({:url => "#goto"})])
			assert_link(links[0], :anchor, :local, true, "(404 Not Found)")
		end

		it "should mark an absolute link" do
			content = "<html><a href=\"#{@root}/link1\">link</a>text</html>"
			links = Page.parse(content, [], @root)
			links.should eql([Link.create({:url => "#{@root}/link1"})])
			assert_link(links[0], :page, :local, true, "(absolute path)")
		end

		it "should return a remote link" do
			content = "<html><a href=\"http://example.org\">link</a>text</html>"
			links = Page.parse(content, [], @root)
			links.should eql([Link.create({:url => "http://example.org"})])
			assert_link(links[0], :page, :remote, false)
		end

		it "should return all kinds of links" do
			content = "<html><a href=\"link1\">link</a>text<img src=\"image2\"></img></html>"
			links = Page.parse(content, [], @root)
			links.should eql([Link.create({:url => "link1"}), Link.create({:url => "image2"})])
			assert_link(links[0], :page, :local, false)
			assert_link(links[1], :image, :local, false)
		end

		it "should not return ignored links" do
			content = "<html><a href=\"link1\">link</a>text<a href=\"link2\">link</a></html>"
			links = Page.parse(content, ["link2"], @root)
			links.should eql([Link.create({:url => "link1"})])
			assert_link(links[0], :page, :local, false)
		end
	end
end