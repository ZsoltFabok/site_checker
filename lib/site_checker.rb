require 'open-uri'
require 'page'
require 'fetch_content'
require 'link'

class SiteChecker
  attr_accessor :ignore_list, :visit_references, :max_recursion_depth

  def initialize()
    yield self if block_given?
    @ignore_list ||= []
    @visit_references ||= false
    @max_recursion_depth ||= -1
  end

  def check(url, root)
    @links = []
    @recursion_depth = 0
    @root = root
    link = Link.create({:url => url, :kind => :page, :location => :local})
    register_visit(link)
    process_local_page(link)
  end

  def local_pages
    get_urls(:local, :page)
  end

  def remote_pages
    get_urls(:remote, :page)
  end

  def local_images
    get_urls(:local, :image)
  end

  def remote_images
    get_urls(:remote, :image)
  end

  def problems
    problems = {}
    @links.each do |link|
      if link.has_problem?
        problems[link.parent_url] ||= []
        problems[link.parent_url] << "#{link.url} #{link.problem}"
      end
    end
    problems
  end

  private
  def get_urls(location, kind)
    @links.find_all do |link|
      if link.location == location && link.kind == kind
        link
      end
    end.map do |link|
      link.url
    end
  end

  def process_local_page(parent)
    links = collect_links(parent)

    links.each do |link|
      link.parent_url = parent.url
link.url = until_issue_7(link.url) # TODO
      unless link.anchor?
        visit(link) unless visited?(link)
      else
        @links << link
      end
    end
  end

  def register_visit(link)
    @links << link unless visited?(link)
  end

  def visited?(link)
    @links.include?(link)
  end

  def visit(link)
    register_visit(link)
    unless link.has_problem?
      unless link.local_page?
        open_reference(link)
      else
        unless stop_recursion?
          @recursion_depth += 1
          process_local_page(link)
          @recursion_depth -= 1
        end
      end
    end
  end

  def open_reference(link)
    content = nil
    begin
      if URI(@root).absolute?
        content = fetch_from_the_web(link)
      else
        content = fetch_from_file_system(link)
      end
    rescue => e
      link.problem = "#{e.message.strip}"
    end
    content
  end

  def fetch_from_file_system(link)
    begin
      location = create_absolute_reference(link.url)
      if link.local_page?
        content = File.open(add_index_html(location)).read
      elsif link.local_image?
        File.open(location)
      elsif @visit_references
        open(link.url)
      end
    rescue Errno::ENOENT => e
      raise "(404 Not Found)"
    rescue => e
      raise "(#{e.message.strip})"
    end
    content
  end

  def fetch_from_the_web(link)
    begin
      uri = create_absolute_reference(link.url)
      if link.local_page?
        content = open(uri)
      elsif link.local_image?
        open(uri)
      elsif @visit_references
        open(uri)
      end
    rescue => e
      raise "(#{e.message.strip})"
    end
    content
  end

  def add_index_html(path)
    path.end_with?(".html") ? path : File.join(path, "index.html")
  end

  def remove_index_html(path)
    path.gsub(/\/index.html$/, "")
  end

  def collect_links(link)
    content = open_reference(link)
    return Page.parse(content, @ignore_list, @root)
  end

  def strip_root(link) # FIXME don't need
    if link
      link.gsub(/^#{@root}[\/]?/, "")
    else
      ""
    end
  end

  def create_absolute_reference(link)
    # FIXME this needs to be where the open/fetch is
    root = URI(@root)
    if root.absolute?
      root.merge(link).to_s.gsub(/\/$/, "")
    else
      # FIXME this is ugly
      if link.start_with?(root.path)
        link
      else
        File.join(root.path, link)
      end
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

  def until_issue_7(link)
    if link.end_with?("/")
      link.gsub(/\/$/, "")
    elsif !link.start_with?("/") && URI(@root).merge(link).absolute?
      link.gsub(/\/$/, "")
    elsif link.start_with?("/")
      link.gsub(/^\//, "")
    else
      link
    end
  end
end
