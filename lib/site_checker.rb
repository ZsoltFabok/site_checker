require 'open-uri'
require 'page'
require 'content_from_file_system'
require 'content_from_web'
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

    @content_reader = get_content_reader

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
  def get_content_reader
    if URI(@root).absolute?
      ContentFromWeb.new(@visit_references, @root)
    else
      ContentFromFileSystem.new(@visit_references, @root)
    end
  end

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
      content = @content_reader.get(link)
    rescue => e
      link.problem = "#{e.message.strip}"
    end
    content
  end

  def collect_links(link)
    content = open_reference(link)
    return Page.parse(content, @ignore_list, @root)
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
