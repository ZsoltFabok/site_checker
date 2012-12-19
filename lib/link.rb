class Link
	attr_accessor :url
	attr_accessor :parent_url
	attr_accessor :kind
	attr_accessor :location
	attr_accessor :problem

	def eql?(other)
    @url.eql? other.url
  end

  def ==(other)
    eql?(other)
  end

  def hash
    @url.hash
  end

  def self.create(attrs)
  	link = Link.new
  	attrs.each do |key, value|
  		if self.instance_methods.include?("#{key}=".to_sym)
  			eval("link.#{key}=value")
  		end
  	end
  	link
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
end