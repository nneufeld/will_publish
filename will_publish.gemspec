Gem::Specification.new do |s|
  s.name        = 'will_publish'
  s.version     = '0.0.0'
  s.date        = '2013-08-25'
  s.summary     = "Provides publishing ability to your Active Record models"
  s.description = "Provides publishing ability to your Active Record models"
  s.authors     = ["Nick Neufeld"]
  s.email       = 'nneufeld@infotech.com'
  s.files       = ["lib/will_publish.rb"]
  s.homepage    = 'http://github.com/nneufeld'
  s.license     = 'MIT'

  s.add_development_dependency "rspec"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "activerecord"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "mysql2"
end