Bundler.require
require "test/unit"
require "active_support/all"
require "active_record"
require "mocha"
require "db/create_db"

require "transitions"
require "active_model/transitions"
require 'random_data'

def create_database
  ActiveRecord::Base.establish_connection(:adapter  => "sqlite3", :database => ":memory:")
  ActiveRecord::Migration.verbose = false
  CreateDb.migrate(:up)
end
