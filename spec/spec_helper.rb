require 'rspec'
require 'debugger'
require 'webmock/rspec'

require File.expand_path('../../lib/site_checker', __FILE__)

# common
def create_link(url)
	SiteChecker::Link.create({:url => url})
end
