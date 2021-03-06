module SiteChecker
  class LinkCollector
    attr_accessor :ignore_list, :visit_references, :max_recursion_depth

    def initialize
      yield self if block_given?
      @ignore_list ||= []
      @visit_references ||= false
      @max_recursion_depth ||= -1
    end

    def check(url, root=nil)
      @links = {}
      @recursion_depth = 0
      @root = figure_out_root(url,root)

      @content_reader = get_content_reader

      link = Link.create({:url => url, :kind => :page, :location => :local})
      register_visit(link)
      process_local_page(link)
      evaluate_anchors
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
      @links.keys.each do |link|
        if link.has_problem?
          problems[link.parent_url] ||= []
          problems[link.parent_url] << "#{link.url} #{link.problem}"
        end
      end
      problems
    end

    private
    def figure_out_root(url, root)
      unless root
        url_uri = URI(url)
        if url_uri.absolute?
          root = "#{url_uri.scheme}://#{url_uri.host}"
        else
          root = url
        end
      end
      root
    end

    def get_content_reader
      if URI(@root).absolute?
        SiteChecker::IO::ContentFromWeb.new(@visit_references, @root)
      else
        SiteChecker::IO::ContentFromFileSystem.new(@visit_references, @root)
      end
    end

    def get_urls(location, kind)
      @links.keys.find_all do |link|
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
        unless link.anchor_related?
          visit(link) unless visited?(link)
        else
          @links[link] = nil
        end
      end
    end

    def register_visit(link)
      @links[link] = nil unless visited?(link)
    end

    def visited?(link)
      @links.has_key?(link)
    end

    def visit(link)
      register_visit(link)
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
      if content
        return SiteChecker::Parse::Page.parse(content, @ignore_list, @root)
      else
        []
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

    def evaluate_anchors
      anchors = @links.keys.find_all {|link| link.anchor?}
      anchor_references = @links.keys.find_all {|link| link.anchor_ref?}
      anchor_references.each do |anchor_ref|
        if find_matching_anchor(anchors, anchor_ref).empty?
          anchor_ref.problem = "(404 Not Found)"
        end
      end
    end

    def find_matching_anchor(anchors, anchor_ref)
      result = []
      anchors.each do |anchor|
        if (anchor.parent_url == anchor_ref.parent_url &&
              anchor_ref.url == "##{anchor.url}") ||
            (anchor.parent_url != anchor_ref.parent_url &&
              anchor_ref.url == "#{anchor.parent_url}##{anchor.url}")
          result << anchor
        end
      end
      result
    end
  end
end
