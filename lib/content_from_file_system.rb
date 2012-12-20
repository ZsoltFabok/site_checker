class ContentFromFileSystem

  def initialize(visit_references, root)
    @visit_references = visit_references
    @root = root
  end

  def get(link)
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

  private
  def add_index_html(path)
    path.end_with?(".html") ? path : File.join(path, "index.html")
  end

  def create_absolute_reference(link)
    if !link.eql?(@root)
      File.join(@root, link)
    else
      @root
    end
  end
end