require "helper"

class Bus
  include Transitions

  state_machine do
    state :parking
  end
end

class TestStatePredicateMethod < Test::Unit::TestCase
  def setup
    @bus = Bus.new
  end

  test "should generate predicate methods for states" do
    assert_true @bus.respond_to?(:parking?)
    assert_true @bus.send(:parking?)
  end
end
