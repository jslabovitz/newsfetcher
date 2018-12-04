require_relative 'lib/newsfetcher/version'

Gem::Specification.new do |s|
  s.name          = 'newsfetcher'
  s.version       = NewsFetcher::VERSION
  s.summary       = 'Handles feeds'
  s.author        = 'John Labovitz'
  s.email         = 'johnl@johnlabovitz.com'
  s.description   = %q{
    NewsFetcher handles feeds
  }
  s.license       = 'MIT'
  s.homepage      = 'http://github.com/jslabovitz/newsfetcher'
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_path  = 'lib'

  s.add_dependency 'faraday', '~> 0'
  s.add_dependency 'feedjira', '~> 2'
  s.add_dependency 'mail', '~> 2'
  s.add_dependency 'maildir', '~> 2'
  s.add_dependency 'path', '~> 2'
  s.add_dependency 'simple-command', '~> 0'

  s.add_development_dependency 'rake', '~> 12'
  s.add_development_dependency 'rubygems-tasks', '~> 0'
end