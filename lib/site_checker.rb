require 'nokogiri'
require 'open-uri'

class SiteChecker
  attr_accessor :visited_local_page
  attr_accessor :visited_external_page
  attr_accessor :visited_image
  attr_accessor :problems
  attr_accessor :filters
  # FIXME it is not really nice here, isn't it?
  attr_accessor :parent_url

  def initialize()
    @visited_local_page = []
    @visited_external_page = []
    @visited_image = []
    @problems = {}
    @filters = []
  end

  def evaluate_page(url, root, options={})
    options = {
      :visit_references => false,
    }.merge(options)

    begin
      if url.start_with?("http://")
        doc = Nokogiri(open(url))
      else
        doc = Nokogiri(load_from_file_system(url))
      end
      reg_local_page_visit(url)
      doc.xpath("//a").reject {|a| filtered?(a['href'])}.each do |a|
        link = a['href']
        if link.start_with?(root)
          new_problem(url, "#{link} (absolute path)")
        elsif link =~ (/^\/.+/)
          @parent_url = url
          current_url = put_link_together(root, link)
          evaluate_page(current_url, root, options) unless local_page_visited?(current_url)
        else
          begin
            unless external_page_visited?(link)
              open(link) if options[:visit_references]
              reg_external_page_visit(link)
            end
          rescue OpenURI::HTTPError => e
            new_problem(url, "#{link} (#{e.message.strip})")
          rescue SocketError => e
            new_problem(url, "#{link} (unknown host)")
          rescue TimeoutError => e
            new_problem(url, "#{link} (network timeout)")
          end
      end
    end

    doc.xpath("//img").reject {|img| filtered?(img['src'])}.each do |img|
      link = img['src']
      if link.start_with?(root)
        new_problem(url, "#{link} (absolute path)")
      else
        link = put_image_link_together(root, link) if link.start_with?("/")
        unless image_visited?(link)
          begin
            if link.start_with?("http://")
              open(link) if options[:visit_references]
            else
              File.open(link)
            end
            reg_image_visit(link)
          rescue OpenURI::HTTPError => e
            new_problem(url, "#{link} (#{e.message.strip})")
          rescue Errno::ENOENT => e
            new_problem(url, "#{link} (404 Not Found)")
          end
        end
      end
    end
    rescue OpenURI::HTTPError => e
      new_problem(parent_url, "#{url} (#{e.message.strip})")
    rescue Errno::ENOENT => e
      new_problem(parent_url, "#{File.join(url, "index.html")} (404 Not Found)")
    end
  end

  def add_filter(link)
    filters << link
  end

  private
  def load_from_file_system(path)
    path = File.join(path, "index.html") unless path.end_with?(".html")
    File.open(path).read
  end

  def put_link_together(root, link)
    if root.start_with?("http://")
      URI(root).merge(link).to_s.gsub(/\/$/, "")
    else
      File.join(root, link)
    end
  end

  def put_image_link_together(root, link)
    if root.start_with?("http://")
      URI(root).merge(link).to_s if link.start_with?("/")
    else
      File.join(root, link)
    end
  end

  def reg_external_page_visit(url)
    reg_visit(@visited_external_page, url)
  end

  def external_page_visited?(url)
    visited?(@visited_external_page, url)
  end

  def reg_local_page_visit(url)
    reg_visit(@visited_local_page, url)
  end

  def local_page_visited?(url)
    visited?(@visited_local_page, url)
  end

  def reg_image_visit(url)
    reg_visit(@visited_image, url)
  end

  def image_visited?(url)
    visited?(@visited_image, url)
  end

  def reg_visit(container, url)
    container << url.gsub(/\/$/, "") unless visited?(container, url.gsub(/\/$/, ""))
  end

  def visited?(container, link)
    container.include?(link.gsub(/\/$/, ""))
  end

  def new_problem(url, message)
    @problems[url] = [] unless problems.has_key?(url)
    @problems[url] << message
  end

  def filtered?(link)
    @filters.include? link
  end
end