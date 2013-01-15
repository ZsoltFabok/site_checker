require 'optparse'

module SiteChecker
	class Cli
		def start
			begin
				options = option_parser

				SiteChecker.configure do |config|
				  config.ignore_list = options[:ignore_list] if options[:ignore_list]
				  config.visit_references = options[:visit_references] if options[:visit_references]
				  config.max_recursion_depth = options[:max_recursion_depth] if options[:max_recursion_depth]
				end

				check_site(ARGV[0], options[:root])

				print_problems_if_any

				print(collected_local_pages, "Collected local pages:") if options[:print_local_pages]
				print(collected_remote_pages, "Collected remote pages:") if options[:print_remote_pages]
				print(collected_local_images, "Collected local images:") if options[:print_local_images]
				print(collected_remote_images, "Collected remote images:") if options[:print_remote_images]

			rescue Interrupt
				puts "Error: Interrupted"
			rescue SystemExit
				puts
			rescue Exception => e
			 	puts "Error: #{e.message}"
			 	puts
			end
		end

		private
		def option_parser
			options = {}
			optparse = OptionParser.new do |opts|
			  opts.banner = "Usage: site_checker [options] <site_url>"

			  opts.on("-e", "--visit-external-references", "Visit external references (may take a bit longer)") do |opt|
			    options[:visit_references] = opt
			  end

			  opts.on("-m", "--max-recursion-depth N", Integer, "Set the depth of the recursion") do |opt|
			    options[:max_recursion_depth] = opt
			  end

			  opts.on("-r", "--root URL", "The root URL of the path") do |opt|
			    options[:root] = opt
			  end

			  opts.on("-i", "--ignore URL", "Ignore the provided URL (can be applied several times)") do |opt|
			    options[:ignore_list] ||= []
			    options[:ignore_list] << opt
			  end

			  opts.on("-p","--print-local-pages", "Prints the list of the URLs of the collected local pages") do |opt|
			    options[:print_local_pages] = opt
			  end

			  opts.on("-x", "--print-remote-pages", "Prints the list of the URLs of the collected remote pages") do |opt|
			    options[:print_remote_pages] = opt
			  end

			  opts.on("-y", "--print-local-images", "Prints the list of the URLs of the collected local images") do |opt|
			    options[:print_local_images] = opt
			  end

			  opts.on("-z", "--print-remote-images", "Prints the list of the URLs of the collected remote images") do |opt|
			    options[:print_remote_images] = opt
			  end

			  opts.on_tail("-h", "--help", "Show a short description and this message") do
			  	puts "Visits the <site_url> and prints out the list of those URLs which cannot be found"
			  	puts
			    puts opts
			    exit
			  end

			  opts.on_tail("-v", "--version", "Show version") do
			    puts SiteChecker::VERSION
			    exit
			  end
			end

			begin
				optparse.parse!
			  if ARGV.size != 1
			  	raise OptionParser::MissingArgument.new("<site_url>")
			  end
		  rescue OptionParser::InvalidOption, OptionParser::MissingArgument, OptionParser::InvalidArgument
			  message = $!.to_s + "\n\n" + optparse.to_s
			  raise Exception.new(message)
			end
		  options
		end

		def print(list, message)
			if not list.empty?
				puts message
				list.sort.each do |entry|
					puts "  #{entry}"
				end
			end
		end

		def print_problems_if_any
			if not collected_problems.empty?
				puts "Collected problems:"
				collected_problems.keys.sort.each do |parent|
					puts "  #{parent}"
					collected_problems[parent].sort.each do |url|
						puts "    #{url}"
					end
				end
			end
		end
	end
end