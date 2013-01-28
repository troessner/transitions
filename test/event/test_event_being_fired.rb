require "helper"

class TestEventBeingFired < Test::Unit::TestCase
  test "should raise an Transitions::InvalidTransition error if the transitions are empty" do
    event = Transitions::Event.new(nil, :event_that_is_fired)
    class AnotherDummy; end
    obj = AnotherDummy.new
    obj.stubs(:current_state).returns(:running)

    exception = assert_raise Transitions::InvalidTransition do
      event.fire(obj)
    end
    assert_match /Can't fire event `event_that_is_fired` in current state `running` for `TestEventBeingFired::AnotherDummy`/, exception.message
  end

  test "should return the state of the first matching transition it finds" do
    event = Transitions::Event.new(nil, :event) do
      transitions :to => :closed, :from => [:open, :received]
    end

    obj = stub
    obj.stubs(:current_state).returns(:open)

    assert_equal :closed, event.fire(obj)
  end
end
