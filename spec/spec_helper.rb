require 'rspec'
require 'webmock/rspec'
require "byebug"

# coveralls for github badge
require 'coveralls'
Coveralls.wear!

require File.expand_path('../../lib/site_checker', __FILE__)

# common
def create_link(url)
  SiteChecker::Link.create({:url => url})
end
