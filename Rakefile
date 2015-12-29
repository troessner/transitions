require 'bundler/gem_tasks'

require 'appraisal'
require 'rake/testtask'
require 'rubocop/rake_task'

Rake::TestTask.new(:test) do |test|
  test.libs = %w(lib test)
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

RuboCop::RakeTask.new do |task|
  task.options << '--display-cop-names'
  task.patterns = ['lib/**/*.rb']
end

task default: :test
task default: :rubocop
