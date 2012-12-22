# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = 'site_checker'
  s.version     = '0.2.0'
  s.date        = '2012-12-20'
  s.summary     = "site_checker-#{s.version}"
  s.description = "A simple tool for checking references on your website"
  s.authors     = ["Zsolt Fabok"]
  s.email       = 'me@zsoltfabok.com'
  s.homepage    = 'https://github.com/ZsoltFabok/site_checker'
  s.license     = 'BSD'

  s.files         = `git ls-files`.split("\n").reject {|path| path =~ /\.gitignore$/ || path =~ /file$/ }
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency('rspec', '2.12.0')
  s.add_development_dependency('webmock', '1.9.0')
  s.add_development_dependency('rake', '10.0.3')
  s.add_development_dependency('yard', '0.8.0')
  s.add_runtime_dependency('nokogiri', '1.5.6')
end
