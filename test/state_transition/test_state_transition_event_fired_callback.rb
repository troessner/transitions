require 'helper'

class Car
  #include Transitions
  include Transitions::ActiveRecordExtension

  include_state_machine
  state_machine do
    state :parked
    state :driving

    event :start_driving do
      transitions :from => :parked, :to => :driving
    end
  end
end

class TestStateTransitionEventFiredCallback < Test::Unit::TestCase
  def setup
    @car = Car.new
  end

  test "should execute the event_fired callback after successfull event execution if it callback is defined" do
    @car.stubs(:event_fired)
    @car.expects(:event_fired).with(:parked, :driving, :start_driving).once

    @car.start_driving!
  end

  test "should not execute the event_fired callback after successfull event execution if it callback is not defined" do
    pend 'Test fails right now although functionality is working as expected'
    # This test fails right now even though it works as expected in the console.
    # The reason for this is, that mocha's `expects` does a little bit more than just set up an expectation,
    # it actually defines this method if it doesn't exist or at least it overwrites respond_to?
    #   @car.respond_to?(:event_fired)
    # returns false before the `expects` call, but true after.
    # Hence, this test fails.
    # Something like
    #   @car.instance_eval { undef :event_fired }
    # doesn't work either, probably because expects just overwrites respond_to?
    # but does not define the method
    # How to fix?
    @car.expects(:event_fired).never
    @car.start_driving!
  end
end
