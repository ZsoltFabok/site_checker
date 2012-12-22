require 'spec_helper'

describe SiteChecker::Link do
	context "#create" do
		it "should create a link with attribute list" do
			link = SiteChecker::Link.create({:kind => :page, :location => "location"})
			link.kind.should eql(:page)
			link.location.should eql("location")
		end
	end

	context "#has_problem?" do
		it "should return true if there are no problem with the link" do
			SiteChecker::Link.create({}).has_problem?.should be_false
		end

	  it "should return false if there are problems with the link" do
			SiteChecker::Link.create({:problem => "grr"}).has_problem?.should be_true
		end
	end

	context "#anchor?" do
		it "should return true for an anchor" do
			SiteChecker::Link.create({:kind => :anchor}).anchor?.should be_true
		end

		it "should return false for non anchor" do
			SiteChecker::Link.create({:kind => :page}).anchor?.should be_false
		end
	end

	context "#anchor_ref?" do
		it "should return true for an anchor_ref" do
			SiteChecker::Link.create({:kind => :anchor_ref}).anchor_ref?.should be_true
		end

		it "should return false for non anchor ref" do
			SiteChecker::Link.create({:kind => :page}).anchor_ref?.should be_false
		end
	end

	context "#anchor_related?" do
		it "should return true for an anchor_ref" do
			SiteChecker::Link.create({:kind => :anchor_ref}).anchor_related?.should be_true
			SiteChecker::Link.create({:kind => :anchor}).anchor_related?.should be_true
		end

		it "should return false for non anchor ref" do
			SiteChecker::Link.create({:kind => :page}).anchor_related?.should be_false
		end
	end

	context "#local_page?" do
		it "should return true if the page is local" do
			SiteChecker::Link.create({:kind => :page, :location => :local}).local_page?.should be_true
		end

		it "should return false if the page is local or not a page at all" do
			SiteChecker::Link.create({:kind => :page, :location => :remote}).local_page?.should be_false
			SiteChecker::Link.create({:kind => :image, :location => :local}).local_page?.should be_false
		end
	end

	context "#local_image?" do
		it "should return true if the image is local" do
			SiteChecker::Link.create({:kind => :image, :location => :local}).local_image?.should be_true
		end

		it "should return false if the image is local or not an image at all" do
			SiteChecker::Link.create({:kind => :image, :location => :remote}).local_image?.should be_false
			SiteChecker::Link.create({:kind => :page, :location => :local}).local_image?.should be_false
		end
	end

	context "#eql" do
		it "should return true if the urls are equal" do
			link1 = SiteChecker::Link.create({:url => "url"})
			link2 = SiteChecker::Link.create({:url => "url"})
			link1.should eql(link2)
		end

		it "should find the link in a collection" do
			link1 = SiteChecker::Link.create({:url => "url"})
			link2 = SiteChecker::Link.create({:url => "url"})
			[link1, link2].should include(link1)
		end

		it "should ignore trailing '/'" do
			link1 = SiteChecker::Link.create({:url => "/url"})
			link2 = SiteChecker::Link.create({:url => "url"})
			link1.should eql(link2)
		end
	end
end