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

  s.add_dependency 'addressable', '~> 2.8'
  s.add_dependency 'faraday', '~> 1.7'
  s.add_dependency 'feedjira', '~> 3.2'
  s.add_dependency 'hashstruct', '~> 1.3'
  s.add_dependency 'loofah', '~> 2.12'
  s.add_dependency 'mail', '~> 2.7'
  s.add_dependency 'path', '~> 2.0'
  s.add_dependency 'sassc', '~> 2.4'
  s.add_dependency 'set_params', '~> 0.1'
  s.add_dependency 'simple-command', '~> 0.4'

  s.add_development_dependency 'bundler', '~> 2.2'
  s.add_development_dependency 'minitest', '~> 5.14'
  s.add_development_dependency 'minitest-power_assert', '~> 0.3'
  s.add_development_dependency 'rake', '~> 13.0'
end