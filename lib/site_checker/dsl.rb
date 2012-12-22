module SiteChecker
  module DSL
    { :check_site              => :check,
      :collected_local_pages   => :local_pages,
      :collected_remote_pages  => :remote_pages,
      :collected_local_images  => :local_images,
      :collected_remote_images => :remote_images,
      :collected_problems      => :problems
     }.each do |dsl_method, method|
      define_method dsl_method do |*args, &block|
        SiteChecker.send method, *args, &block
      end
    end
  end
end

include SiteChecker::DSL