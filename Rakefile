require 'bundler/gem_tasks'

require 'appraisal'
require 'rake/testtask'
require 'rubocop/rake_task'
require 'reek/rake/task'

Rake::TestTask.new(:test) do |test|
  test.libs = %w(lib test)
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

RuboCop::RakeTask.new do |task|
  task.options << '--display-cop-names'
  task.patterns = ['lib/**/*.rb']
end

Reek::Rake::Task.new

task default: [:test, :reek, :rubocop]
