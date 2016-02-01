# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'transitions/version'

Gem::Specification.new do |spec|
  spec.name          = 'transitions'
  spec.version       = Transitions::VERSION
  spec.authors       = ['Timo Rößner']
  spec.email         = ['timo.roessner@googlemail.com']

  spec.summary       = 'State machine extracted from ActiveModel'
  spec.description   = 'Lightweight state machine extracted from ActiveModel'
  spec.homepage      = 'http://github.com/troessner/transitions'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.0'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'test-unit', '~> 2.5'
  spec.add_development_dependency 'mocha', '~> 0.11.0' # With mocha 0.12 we get: undefined method `run' for #<StateMachineMachineTest:0x94918b8> (NoMethodError)
  spec.add_development_dependency 'random_data'
  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency 'activerecord', ['>= 3.0', '<= 4.0']
  spec.add_development_dependency 'rubocop', '~> 0.36'
end
