require 'site_checker/io/io_spec_helper'
require 'open3'

module CliSpecHelper
  include IoSpecHelper

  def exec(command, arguments)
  	stdin, stdout, stderr = Open3.popen3("ruby -Ilib #{command} #{arguments}")
		stdout.readlines.map {|line| line.chomp}.join("\n")
	end

	def option_list
		"Usage: site_checker [options] <site_url>\n" +
		"    -e, --visit-external-references  Visit external references (may take a bit longer)\n" +
		"    -m, --max-recursion-depth N      Set the depth of the recursion\n" +
		"    -r, --root URL                   The root URL of the path\n" +
		"    -i, --ignore URL                 Ignore the provided URL (can be applied several times)\n" +
		"    -p, --print-local-pages          Prints the list of the URLs of the collected local pages\n" +
		"    -x, --print-remote-pages         Prints the list of the URLs of the collected remote pages\n" +
		"    -y, --print-local-images         Prints the list of the URLs of the collected local images\n" +
		"    -z, --print-remote-images        Prints the list of the URLs of the collected remote images\n" +
		"    -h, --help                       Show a short description and this message\n" +
		"    -v, --version                    Show version\n"
	end
end