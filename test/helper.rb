Bundler.require
require "test/unit"
require "active_support/all"
require "active_record"
require "mocha"
require "db/create_db"
require "ruby-debug"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "transitions"
require "active_record/transitions"

class Test::Unit::TestCase

end

def create_database
  ActiveRecord::Base.establish_connection(:adapter  => "sqlite3", :database => ":memory:")
  ActiveRecord::Migration.verbose = false
  CreateDb.migrate(:up)
end
