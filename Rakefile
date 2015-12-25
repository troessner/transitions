require 'bundler/gem_tasks'

require 'appraisal'
require 'rake/testtask'
require 'rubocop/rake_task'

Rake::TestTask.new(:test) do |test|
  test.libs = %w(lib test)
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

RuboCop::RakeTask.new

task default: :test
