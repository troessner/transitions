require "rubygems"
gem "test-unit" # enforce gem usage on 1.8.x
require "test/unit"
require "active_record"
require "mocha"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "transitions"
require "active_record/transitions"

class Test::Unit::TestCase

end
