Gem::Specification.new do |s|
  s.name        = 'site_checker'
  s.version     = '0.0.0'
  s.date        = '2012-07-15'
  s.summary     = "site_checker-#{s.version}"
  s.description = "A simple tool for checking references on your website"
  s.authors     = ["Zsolt Fabok"]
  s.email       = 'me@zsoltfabok.com'
  s.files       = ["lib/site_checker.rb"]
  s.homepage    = 'https://github.com/ZsoltFabok/site_checker'

  s.add_development_dependency 'rspec', '~> 2.11', '>= 2.11.0'
  s.add_runtime_dependency 'nokogiri', '~> 1.5', '>= 1.5.5'
end
