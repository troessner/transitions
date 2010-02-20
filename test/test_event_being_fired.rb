require "helper"

class TestEventBeingFired < Test::Unit::TestCase
  test "should raise an StateMachine::InvalidTransition error if the transitions are empty" do
    event = StateMachine::Event.new(nil, :event)

    assert_raise StateMachine::InvalidTransition do
      event.fire(nil)
    end
  end

  test "should return the state of the first matching transition it finds" do
    event = StateMachine::Event.new(nil, :event) do
      transitions :to => :closed, :from => [:open, :received]
    end

    obj = stub
    obj.stubs(:current_state).returns(:open)

    assert_equal :closed, event.fire(obj)
  end
end
