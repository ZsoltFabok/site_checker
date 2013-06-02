require 'rspec'
require 'webmock/rspec'

begin
  require "debugger"
rescue LoadError
  # most probably using 1.8
  require "ruby-debug"
end

# coveralls for github badge
require 'coveralls'
Coveralls.wear!

require File.expand_path('../../lib/site_checker', __FILE__)

# common
def create_link(url)
  SiteChecker::Link.create({:url => url})
end
