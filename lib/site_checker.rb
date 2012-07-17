require 'nokogiri'
require 'open-uri'

class SiteChecker
  attr_accessor :problems
  attr_accessor :ignore_list, :visit_references, :max_recursion_depth

  def initialize()
    yield self if block_given?  
    @ignore_list ||= []
    @visit_references ||= false
    @max_recursion_depth ||= -1
  end

  def check(url, root)
    @visits = {}
    @problems = {}
    @recursion_depth = 0
    
    @root = root

    register_visit(:local_page, url)
    process_local_page(url, nil)
  end

  def local_pages
    @visits[:local_page]
  end

  def remote_pages
    @visits[:remote_page]
  end

  def local_images
    @visits[:local_image]
  end

  def remote_images
    @visits[:remote_image]
  end

  private
  def process_local_page(url, parent_url)
    links = collect_links(url, parent_url)

    filter_out_working_anchors!(links)
    report_and_remove_anchors!(links, parent_url)

    links.each do |link, kind|
      if kind != :anchor
        visit(kind, url, link) unless visited?(kind, link)
      else
      end
    end
  end

  def register_visit(kind, link)
    @visits[kind] = [] unless @visits.has_key?(kind)
    @visits[kind] << link
  end

  def visited?(kind, link)
    @visits[kind] = [] unless @visits.has_key?(kind)
    @visits[kind].include?(link)
  end

  def visit(kind, parent_url, link)
      register_visit(kind, link)
      if kind != :local_page
        open_reference(kind, link, parent_url)
      else
        unless stop_recursion?
          @recursion_depth += 1
          process_local_page(link, parent_url)
          @recursion_depth -= 1
        end
      end
  end

  def open_reference(kind, link, parent_url)
    content = nil
    begin
      if kind == :local_page
        if URI(@root).absolute?
          content = open(link)
        else
          link = add_index_html(link)
          content = File.open(link).read
        end
      elsif kind == :local_image
        if URI(@root).absolute?
          open(link)
        else
          File.open(link)
        end
      elsif @visit_references
        open(link)
      end
    rescue OpenURI::HTTPError => e
      new_problem(strip_root(parent_url), "#{strip_root(link)} (#{e.message.strip})")
    rescue Errno::ENOENT => e
      link = remove_index_html(link) if kind == :local_page
      new_problem(strip_root(parent_url), "#{strip_root(link)} (404 Not Found)")
    rescue => e
      new_problem(strip_root(parent_url), "#{strip_root(link)} (#{e.message.strip})")
    end
    content
  end

  def filter_out_working_anchors!(links)
    links.delete_if{ |link, kind| (kind == :local_page && has_anchor?(links, link)) }
  end

  def report_and_remove_anchors!(links, parent_url)
    anchors = links.select {|link, kind| link.match(/^.+#.+$/) && kind == :local_page}
    anchors.each do |anchor, kind|
      new_problem(strip_root(parent_url), "#{strip_root(anchor)} (404 Not Found)")
      links.delete(anchor)
    end
  end

  def has_anchor?(links, link)
    anchor = link.gsub(/^.+#/, "")
    links.has_key?(anchor) && links[anchor] == :anchor
  end


  def absolute_reference?(link)
    link.start_with?(@root)
  end

  def relative_reference?(link)
    link =~ /^\/.+/
  end

  def collect_links(url, parent_url)
    links = {}
    content = open_reference(:local_page, url, parent_url)
    if content
      doc = Nokogiri(content)
      doc.xpath("//img").reject {|img| ignored?(img['src'])}.each do |img|
        link_kind = detect_link_and_kind(img['src'], url, :remote_image, :local_image)
        links.merge!(link_kind) unless link_kind.empty?    
      end
      doc.xpath("//a").reject {|a| ignored?(a['href'])}.each do |a|
        link_kind = detect_link_and_kind(a['href'], url, :remote_page, :local_page)
        links.merge!(link_kind) unless link_kind.empty?
      end
    
      doc.xpath("//a").reject {|a| !a['id']}.each do |a|
        links.merge!({a['id'] => :anchor})
      end
    end
    links
  end

  def detect_link_and_kind(reference, url, external_kind, local_kind)
    link_kind = {}
    link = URI(strip_trailing_slash(reference))
    if link.to_s.start_with?(@root)
      new_problem(url, "#{link} (absolute path)")
    else
      if URI(reference).absolute?
        link_kind[link.to_s] = external_kind
      else
        link_kind[create_absolute_reference(link.to_s)] = local_kind
      end
    end
    link_kind
  end

  def strip_trailing_slash(link)
    link.gsub(/\/$/, "")
  end

  def strip_root(link)
    if link
      link.gsub(/^#{@root}[\/]?/, "")
    else
      ""
    end
  end

  def add_index_html(path)
    path.end_with?(".html") ? path : File.join(path, "index.html") 
  end

  def remove_index_html(path)
    path.gsub(/\/index.html$/, "")
  end

  def create_absolute_reference(link)
    root = URI(@root)
    if root.absolute?
      root.merge(link).to_s.gsub(/\/$/, "")
    else
      File.join(root.path, link)
    end
  end

  def new_problem(url, message)
    url = @root if url.empty?
    @problems[url] = [] unless problems.has_key?(url)
    @problems[url] << message
  end

  def ignored?(link)
    if link
      @ignore_list.include? link
    else
      true
    end
  end
  
  def stop_recursion?
    if @max_recursion_depth == -1
      false
    elsif @max_recursion_depth > @recursion_depth
      false
    else
      true
    end
  end
end
