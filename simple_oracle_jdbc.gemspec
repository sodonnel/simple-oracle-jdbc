Gem::Specification.new do |s| 
  s.name = "simpleOracleJDBC"
  s.version = "0.1"
  s.author = "Stephen O'Donnell"
  s.email = "stephen@betteratoracle.com"
  s.homepage = "http://betteratoracle.com"
  s.platform = Gem::Platform::RUBY
  s.summary = "A gem to simplify JDBC database access to Oracle when using JRuby"
  s.files = (Dir.glob("{test,lib}/**/*") + Dir.glob("[A-Z]*")).reject{ |fn| fn.include? "temp" }

  s.require_path = "lib"
  s.description  = "A gem to simplify JDBC database access to Oracle when using JRuby"
#  s.autorequire = "name"
#  s.test_files = FileList["{test}/**/*test.rb"].to_a
  s.has_rdoc = false
#  s.extra_rdoc_files = ["README"]
#  s.add_dependency("dependency", ">= 0.x.x")
end