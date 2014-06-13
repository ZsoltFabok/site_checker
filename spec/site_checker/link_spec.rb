require 'spec_helper'

describe SiteChecker::Link do
  context "#create" do
    it "should create a link with attribute list" do
      link = SiteChecker::Link.create({:kind => :page, :location => "location"})
      expect(link.kind).to eq(:page)
      expect(link.location).to eq("location")
    end
  end

  context "#has_problem?" do
    it "should return true if there are no problem with the link" do
      expect(SiteChecker::Link.create({}).has_problem?).to be false
    end

    it "should return false if there are problems with the link" do
      expect(SiteChecker::Link.create({:problem => "grr"}).has_problem?).to be true
    end
  end

  context "#anchor?" do
    it "should return true for an anchor" do
      expect(SiteChecker::Link.create({:kind => :anchor}).anchor?).to be true
    end

    it "should return false for non anchor" do
      expect(SiteChecker::Link.create({:kind => :page}).anchor?).to be false
    end
  end

  context "#anchor_ref?" do
    it "should return true for an anchor_ref" do
      expect(SiteChecker::Link.create({:kind => :anchor_ref}).anchor_ref?).to be true
    end

    it "should return false for non anchor ref" do
      expect(SiteChecker::Link.create({:kind => :page}).anchor_ref?).to be false
    end
  end

  context "#anchor_related?" do
    it "should return true for an anchor_ref" do
      expect(SiteChecker::Link.create({:kind => :anchor_ref}).anchor_related?).to be true
      expect(SiteChecker::Link.create({:kind => :anchor}).anchor_related?).to be true
    end

    it "should return false for non anchor ref" do
      expect(SiteChecker::Link.create({:kind => :page}).anchor_related?).to be false
    end
  end

  context "#local_page?" do
    it "should return true if the page is local" do
      expect(SiteChecker::Link.create({:kind => :page, :location => :local}).local_page?).to be true
    end

    it "should return false if the page is local or not a page at all" do
      expect(SiteChecker::Link.create({:kind => :page, :location => :remote}).local_page?).to be false
      expect(SiteChecker::Link.create({:kind => :image, :location => :local}).local_page?).to be false
    end
  end

  context "#local_image?" do
    it "should return true if the image is local" do
      expect(SiteChecker::Link.create({:kind => :image, :location => :local}).local_image?).to be true
    end

    it "should return false if the image is local or not an image at all" do
      expect(SiteChecker::Link.create({:kind => :image, :location => :remote}).local_image?).to be false
      expect(SiteChecker::Link.create({:kind => :page, :location => :local}).local_image?).to be false
    end
  end

  context "#eql" do
    it "should return true if the urls are equal" do
      link1 = SiteChecker::Link.create({:url => "url"})
      link2 = SiteChecker::Link.create({:url => "url"})
      expect(link1).to eq(link2)
    end

    it "should find the link in a collection" do
      link1 = SiteChecker::Link.create({:url => "url"})
      link2 = SiteChecker::Link.create({:url => "url"})
      expect([link1, link2].include?(link1)).to be true
    end

    it "should ignore trailing '/'" do
      link1 = SiteChecker::Link.create({:url => "/url"})
      link2 = SiteChecker::Link.create({:url => "url"})
      expect(link1).to eq(link2)
    end
  end
end