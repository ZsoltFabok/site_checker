require 'nokogiri'
require 'open-uri'
require 'link'

class Page
	def self.parse(content, ignore_list, root)
		links = []
		page = Nokogiri(content)

		page.xpath("//a").reject {|a| ignored?(ignore_list, a['href'])}.each do |a|
			links << Link.create({:url => strip_trailing_slash(a['href']), :kind => :page})
		end

		page.xpath("//img").reject {|img| ignored?(ignore_list, img['src'])}.each do |img|
			links << Link.create({:url => img['src'], :kind => :image})
		end

		set_location(links, root)
		set_anchors(links, page)
		links
	end

	private
	def self.set_location(links, root)
		links.each do |link|
	    uri = URI(link.url)
	    if uri.to_s.start_with?(root)
	    	link.problem = "(absolute path)"
	    else
	      if uri.absolute?
	        link.location = :remote
	      else
	        link.location = :local
	      end
	    end
	  end
	end

	def self.ignored?(ignore_list, link)
    if link
      ignore_list.include? link
    else
      true
    end
  end

  def self.strip_trailing_slash(link) # TODO
    link.gsub(/\/$/, "")
  end

  def self.get_local_anchor_references(page)
  	page.xpath("//a").reject {|a| !a['id']}.map {|a| a['id']}
  end

  def self.set_anchors(links, page)
  	refs = get_local_anchor_references(page)
  	links.each do |link|
  		if link.url.start_with?("#")
  			link.kind = :anchor
  			if !refs.include?(link.url.gsub(/#/, ""))
  				link.problem = "(404 Not Found)"
  			end
  		end
  	end
  end
end