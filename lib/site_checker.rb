require 'open-uri'
require 'nokogiri'

require 'site_checker/io/content_from_file_system'
require 'site_checker/io/content_from_web'
require 'site_checker/parse/page'
require 'site_checker/link'
require 'site_checker/link_collector'
require 'site_checker/dsl'

module SiteChecker
  class << self
    attr_accessor :ignore_list
    attr_accessor :visit_references
    attr_accessor :max_recursion_depth
    attr_accessor :dsl_enabled
    attr_reader   :link_collector

    ##
    # The following configuration options, which can be used together, are available:
    #
    # - ignoring certain links:
    #
    #     SiteChecker.configure do |config|
    #       config.ignore_list = ["/", "/atom.xml"]
    #     end
    #
    # - visit the external references as well:
    #
    #     SiteChecker.configure do |config|
    #       config.visit_references = true
    #     end
    #
    # - set the depth of the recursion:
    #
    #     SiteChecker.configure do |config|
    #       config.max_recursion_depth = 3
    #     end
    def configure
      yield self
    end

    ##
    # Recursively visits the provided url looking for reference problems.
    #
    # @param [String] url where the processing starts
    # @param [String] root (optional) the root URL of the site. If not provided then the method will use the url to figure it out.
    #
    def check(url, root=nil)
      create_instance
      @link_collector.check(url, root)
    end

    ##
    # Returns the Array of the visited local pages.
    #
    # @return [Array] list of the visited local pages
    #
    def local_pages
      @link_collector.local_pages
    end

    ##
    # Returns the Array of the visited remote (external) pages.
    #
    # @return [Array] list of the visited remote pages
    #
    def remote_pages
      @link_collector.remote_pages
    end

    ##
    # Returns the Array of the visited local images.
    #
    # @return [Array] list of the visited local images
    #
    def local_images
      @link_collector.local_images
    end

    ##
    # Returns the Array of the visited remote (external) images.
    #
    # @return [Array] list of the visited remote images
    #
    def remote_images
      @link_collector.remote_images
    end

    ##
    # Returns the Hash (:parent_url => [Array of problematic links]) of the problems.
    #
    # @return [Hash] the result of the check
    #
    def problems
      @link_collector.problems
    end

    private
    def create_instance
      @link_collector = SiteChecker::LinkCollector.new do |config|
        config.visit_references = @visit_references if @visit_references
        config.ignore_list = @ignore_list if @ignore_list
        config.max_recursion_depth = @max_recursion_depth if @max_recursion_depth
      end
    end
  end
end