require 'nokogiri'
require 'open-uri'
require 'link'

class Page
	def self.parse(content, ignore_list, root)
		links = []
		page = Nokogiri(content)

		links.concat(get_links(page, ignore_list, root))
		links.concat(get_images(page, ignore_list, root))
		links.concat(get_anchors(page))
		links.concat(local_pages_which_has_anchor_references(links, root))

		links.uniq
	end

	private
	def self.get_links(page, ignore_list, root)
		links = []
		page.xpath("//a").reject {|a| ignored?(ignore_list, a['href'])}.each do |a|
			if a['href'].match(/(.*)#.+/) && !URI($1).absolute?
				kind = :anchor_ref
			else
				kind = :page
			end
			links << Link.create({:url => a['href'], :kind => kind})
		end
		set_location(links, root)
	end

	def self.get_images(page, ignore_list, root)
		links = []
		page.xpath("//img").reject {|img| ignored?(ignore_list, img['src'])}.each do |img|
			links << Link.create({:url => img['src'], :kind => :image})
		end
		set_location(links, root)
	end

	def self.set_location(links, root)
		links.each do |link|
	    uri = URI(link.url)
	    if uri.to_s.start_with?(root)
	    	link.problem = "(absolute path)"
	    	link.location = :local
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

  def self.get_anchors(page)
  	anchors = []
  	page.xpath("//a").reject {|a| !a['id']}.each do |a|
  		anchors << Link.create({:url => a['id'], :kind => :anchor})
  	end
  	anchors
  end

  def self.local_pages_which_has_anchor_references(links, root)
  	new_links = []
  	links.find_all {|link| link.anchor_ref?}.each do |link|
  		uri = URI(link.url)
  		if link.url.match(/(.+)#/)
  			new_links << Link.create({:url => $1, :kind => :page})
  		end
  	end
  	set_location(new_links, root)
  end
end