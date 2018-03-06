# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'feeder/version'

Gem::Specification.new do |spec|
  spec.name          = 'feeder'
  spec.version       = Feeder::VERSION
  spec.authors       = ["John Labovitz"]
  spec.email         = ['johnl@johnlabovitz.com']

  spec.summary       = %q{Handles feeds.}
  spec.description   = %q{Feeder handles feeds}
  # spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = 'MIT'
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'feedjira'
  spec.add_dependency 'hashstruct'
  spec.add_dependency 'maildir'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'nokogiri-plist'
  spec.add_dependency 'path'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest'
end