module SiteChecker
  class LinkCollector
    attr_accessor :ignore_list, :visit_references, :max_recursion_depth

    ##
    # The following configuration options, which can be used together, are available:
    #
    # - ignoring certain links:
    #
    #     site_checker = SiteChecker.new do |s|
    #       s.ignore_list = ["/", "/atom.xml"]
    #     end
    #
    # - visit the external references as well:
    #
    #     site_checker = SiteChecker.new do |s|
    #       s.visit_references = true
    #     end
    #
    # - set the depth of the recursion:
    #
    #     site_checker = SiteChecker.new do |s|
    #       s.max_recursion_depth = 3
    #     end
    def initialize
      yield self if block_given?
      @ignore_list ||= []
      @visit_references ||= false
      @max_recursion_depth ||= -1
    end

    ##
    # Recursively visits the provided url looking for reference problems.
    #
    # @param [String] url where the processing starts
    # @param [String] root the root URL of the site
    #
    def check(url, root)
      @links = []
      @recursion_depth = 0
      @root = root

      @content_reader = get_content_reader

      link = Link.create({:url => url, :kind => :page, :location => :local})
      register_visit(link)
      process_local_page(link)
      evaluate_anchors
    end

    ##
    # Returns the Array of the visited local pages.
    #
    # @return [Array] list of the visited local pages
    #
    def local_pages
      get_urls(:local, :page)
    end

    ##
    # Returns the Array of the visited remote (external) pages.
    #
    # @return [Array] list of the visited remote pages
    #
    def remote_pages
      get_urls(:remote, :page)
    end

    ##
    # Returns the Array of the visited local images.
    #
    # @return [Array] list of the visited local images
    #
    def local_images
      get_urls(:local, :image)
    end

    ##
    # Returns the Array of the visited remote (external) images.
    #
    # @return [Array] list of the visited remote images
    #
    def remote_images
      get_urls(:remote, :image)
    end

    ##
    # Returns the Hash (:parent_url => [Array of problematic links]) of the problems.
    #
    # @return [Hash] the result of the check
    #
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
        SiteChecker::IO::ContentFromWeb.new(@visit_references, @root)
      else
        SiteChecker::IO::ContentFromFileSystem.new(@visit_references, @root)
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
        unless link.anchor_related?
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
      return SiteChecker::Parse::Page.parse(content, @ignore_list, @root)
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
      anchors = @links.find_all {|link| link.anchor?}
      anchor_references = @links.find_all {|link| link.anchor_ref?}
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
