require 'rubygems'
require 'rspec'
require 'debugger'

require 'webmock/rspec'

require File.expand_path('../../lib/site_checker', __FILE__)

def webmock(uri, status, content)
	stub_request(:get, uri).
    with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
    to_return(:status => status, :body => content)
end

def filesystemmock(uri, content)
	FileUtils.mkdir_p(File.dirname(File.join(fs_test_path, uri)))
	File.open(File.join(fs_test_path, uri), "w") do |f|
		f.write(content)
	end
end

def clean_fs_test_path
	FileUtils.rm_rf(fs_test_path)
end

def fs_test_path
	"test_data_public"
end

def assert_link(link, kind, location, has_problem, problem=nil)
	link.kind.should eql(kind)
	link.location.should eql(location)
	link.has_problem?.should eql(has_problem)
	link.problem.should eql(problem) if problem
end