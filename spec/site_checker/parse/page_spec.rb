require 'spec_helper'
require_relative 'parse_spec_helper'

describe SiteChecker::Parse::Page do
	include ParseSpecHelper
	context "#parse" do
		before(:each) do
			@root = "http://localhost:4000"
		end

		it "should return the containing local links" do
			content = "<html><a href=\"link1\">link</a>text<a href=\"link2\">link</a></html>"
			links = SiteChecker::Parse::Page.parse(content, [], @root)
			links.should eql([create_link("link1"), create_link("link2")])
			assert_link(links[0], :page, :local, false)
			assert_link(links[1], :page, :local, false)
		end

		it "should return the containing local images" do
			content = "<html><img src=\"image1\"></img>link</a>text<img src=\"image2\"></img></html>"
			links = SiteChecker::Parse::Page.parse(content, [], @root)
			links.should eql([create_link("image1"), create_link("image2")])
			assert_link(links[0], :image, :local, false)
			assert_link(links[1], :image, :local, false)
		end

		it "should return an anchor with its anchor reference" do
			content = "<html><a href=\"#goto\">link</a>text<a id=\"goto\"></a></html>"
			links = SiteChecker::Parse::Page.parse(content, [], @root)
			links.should eql([create_link("#goto"), create_link("goto")])
			assert_link(links[0], :anchor_ref, :local, false)
			assert_link(links[1], :anchor, nil, false)
		end

		it "should mark an absolute link" do
			content = "<html><a href=\"#{@root}/link1\">link</a>text</html>"
			links = SiteChecker::Parse::Page.parse(content, [], @root)
			links.should eql([create_link("#{@root}/link1")])
			assert_link(links[0], :page, :local, true, "(absolute path)")
		end

		it "should return a remote link" do
			content = "<html><a href=\"http://example.org\">link</a>text</html>"
			links = SiteChecker::Parse::Page.parse(content, [], @root)
			links.should eql([create_link("http://example.org")])
			assert_link(links[0], :page, :remote, false)
		end

		it "should return all kinds of links" do
			content = "<html><a href=\"link1\">link</a>text<img src=\"image2\"></img></html>"
			links = SiteChecker::Parse::Page.parse(content, [], @root)
			links.should eql([create_link("link1"), create_link("image2")])
			assert_link(links[0], :page, :local, false)
			assert_link(links[1], :image, :local, false)
		end

		it "should not return ignored links" do
			content = "<html><a href=\"link1\">link</a>text<a href=\"link2\">link</a></html>"
			links = SiteChecker::Parse::Page.parse(content, ["link2"], @root)
			links.should eql([create_link("link1")])
			assert_link(links[0], :page, :local, false)
		end

		it "should return a link only once" do
			content = "<html><a href=\"link1\">link</a>text<a href=\"link1\">link</a></html>"
			links = SiteChecker::Parse::Page.parse(content, [], @root)
			links.should eql([create_link("link1")])
			assert_link(links[0], :page, :local, false)
		end
	end
end