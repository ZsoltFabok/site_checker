require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc "By default run the test cases"
task :default  => :spec