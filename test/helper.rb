require 'test/unit'
require 'active_record'

require 'transitions'
#require 'active_model/transitions'
require 'transitions/active_model/transitions'

require 'mocha'
require 'random_data'


def db_defaults!
  ActiveRecord::Base.establish_connection(:adapter  => 'sqlite3', :database => ':memory:')
  ActiveRecord::Migration.verbose = false
end

def set_up_db(*migrations)
  db_defaults!
  migrations.each { |klass| klass.send :migrate, :up }
end
