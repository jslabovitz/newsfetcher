require_relative 'lib/feeder/version'

Gem::Specification.new do |s|
  s.name          = 'feeder'
  s.version       = Feeder::VERSION
  s.summary       = 'Handles feeds.'
  s.author        = 'John Labovitz'
  s.email         = 'johnl@johnlabovitz.com'
  s.description   = %q{
    Feeder handles feeds
  }
  s.license       = 'MIT'
  s.homepage      = 'http://github.com/jslabovitz/feeder'
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_path  = 'lib'

  s.add_dependency 'feedjira', '~> 0'
  s.add_dependency 'hashstruct', '~> 0'
  s.add_dependency 'maildir', '~> 0'
  s.add_dependency 'nokogiri', '~> 0'
  s.add_dependency 'nokogiri-plist', '~> 0'
  s.add_dependency 'path', '~> 0'

  s.add_development_dependency 'rake', '~> 12.3'
  s.add_development_dependency 'rubygems-tasks', '~> 0.2'
end