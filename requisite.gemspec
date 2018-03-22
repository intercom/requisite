# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'requisite/version'

Gem::Specification.new do |gem|
  gem.name          = 'requisite'
  gem.version       = Requisite::VERSION
  gem.authors       = ['James Osler']
  gem.email         = ['jamie@intercom.io']
  gem.summary       = 'Strongly defined models for HTTP APIs'
  gem.description   = %q{ Requisite is an elegant way of strongly defining request and response models for serialization }
  gem.homepage      = 'https://www.intercom.io'
  gem.license       = 'Apache License Version 2.0'
  gem.add_development_dependency "minitest"
  gem.add_development_dependency "rake"
  gem.add_runtime_dependency "actionpack", ">= 4.2.0"
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
end
