require 'rubygems'
gem "test-unit"
gem 'mongoid'
require "test/unit"
require 'mongoid'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "transitions"
require "mongoid/transitions"

Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db('transitions_test')
  config.allow_dynamic_fields = false
end

