require 'spec_helper'

describe Link do
	context "#create" do
		it "should create a link with attribute list" do
			link = Link.create({:kind => :page, :location => "location"})
			link.kind.should eql(:page)
			link.location.should eql("location")
		end
	end

	context "#has_problem?" do
		it "should return true if there are no problem with the link" do
			Link.new.has_problem?.should be_false
		end

	  it "should return false if there are problems with the link" do
			Link.create({:problem => "grr"}).has_problem?.should be_true
		end
	end

	context "#anchor?" do
		it "should return true for an anchor" do
			Link.create({:kind => :anchor}).anchor?.should be_true
		end

		it "should return false for non anchor" do
			Link.create({:kind => :page}).anchor?.should be_false
		end
	end

	context "#local_page?" do
		it "should return true if the page is local" do
			Link.create({:kind => :page, :location => :local}).local_page?.should be_true
		end

		it "should return false if the page is local or not a page at all" do
			Link.create({:kind => :page, :location => :remote}).local_page?.should be_false
			Link.create({:kind => :image, :location => :local}).local_page?.should be_false
		end
	end

	context "#local_image?" do
		it "should return true if the image is local" do
			Link.create({:kind => :image, :location => :local}).local_image?.should be_true
		end

		it "should return false if the image is local or not an image at all" do
			Link.create({:kind => :image, :location => :remote}).local_image?.should be_false
			Link.create({:kind => :page, :location => :local}).local_image?.should be_false
		end
	end

	context "#eql" do
		it "should return true if the urls are equal" do
			link1 = Link.create({:url => "url"})
			link2 = Link.create({:url => "url"})
			link1.should eql(link2)
		end

		it "should find the link in a collection" do
			link1 = Link.create({:url => "url"})
			link2 = Link.create({:url => "url"})
			[link1, link2].should include(link1)
		end

		it "should ignore trailing '/'" do
			link1 = Link.create({:url => "/url"})
			link2 = Link.create({:url => "url"})
			link1.should eql(link2)
		end
	end
end