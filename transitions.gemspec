# -*- encoding: utf-8 -*-

require 'transitions'

Gem::Specification.new do |s|
  s.name = "transitions"
  s.version = Transitions::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Jakub Kuźma"]
  s.email = "qoobaa@gmail.com"
  s.homepage = "http://github.com/qoobaa/transitions"
  s.summary = "State machine extracted from ActiveModel"
  s.description = "Lightweight state machine extracted from ActiveModel"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_development_dependency "test-unit", [">= 2.0"]
  s.add_development_dependency "mocha"
  s.add_development_dependency "sqlite3-ruby"
  s.add_development_dependency "activerecord"

  s.files = Dir.glob("lib/**/*") + %w(LICENSE README.rdoc)
end
