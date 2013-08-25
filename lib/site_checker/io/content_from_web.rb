module SiteChecker
  module IO
    class ContentFromWeb

    	def initialize(visit_references, root)
    		@visit_references = visit_references
    		@root = root
    	end

    	def get(link)
        begin
          uri = create_absolute_reference(link.url)
          if link.local_page?
            content = open(uri)
            if !content.meta['content-type'].start_with?('text/html')
              raise "not a text/html content-type"
            end
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

      private
      def create_absolute_reference(link)
        if link.start_with?(@root)
          URI(link)
        else
          URI(@root).merge(link)
        end
      end
    end
  end
end