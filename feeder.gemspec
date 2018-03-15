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

  s.add_dependency 'faraday', '~> 0.14'
  s.add_dependency 'feedjira', '~> 2.1'
  s.add_dependency 'hashstruct', '~> 1.3'
  s.add_dependency 'mail', '~> 2.7'
  s.add_dependency 'maildir', '~> 2.2'
  s.add_dependency 'nokogiri-plist', '~> 0.5'
  s.add_dependency 'path', '~> 2.0'
  s.add_dependency 'simple_option_parser', '~> 0.3'

  s.add_development_dependency 'rake', '~> 12.3'
  s.add_development_dependency 'rubygems-tasks', '~> 0.2'
end