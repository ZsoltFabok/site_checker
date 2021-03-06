module SiteChecker
  class Link
    attr_accessor :url
    attr_accessor :modified_url
    attr_accessor :parent_url
    attr_accessor :kind
    attr_accessor :location
    attr_accessor :problem

    def eql?(other)
      @modified_url.eql? other.modified_url
    end

    def ==(other)
      eql?(other)
    end

    def hash
      @modified_url.hash
    end

    def self.create(attrs)
      link = Link.new
      attrs.each do |key, value|
        if self.instance_methods.map{|m| m.to_s}.include?("#{key}=")
          eval("link.#{key}=value")
        end
      end
      link
    end

    def parent_url=(parent_url)
      @modified_url = "#{parent_url}##{@url}" if anchor?
      @parent_url = parent_url
    end

    def url=(url)
      @modified_url = ignore_trailing_slash(url)
      @url = url
    end

    def has_problem?
      @problem != nil
    end

    def local_page?
      @location == :local && @kind == :page
    end

    def local_image?
      @location == :local && @kind == :image
    end

    def anchor?
      @kind == :anchor
    end

    def anchor_ref?
      @kind == :anchor_ref
    end

    def anchor_related?
      anchor? || anchor_ref?
    end

    private
    def ignore_trailing_slash(url)
      url.gsub(/^\//,"")
    end
  end
end