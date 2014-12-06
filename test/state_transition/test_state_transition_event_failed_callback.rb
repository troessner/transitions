require 'helper'

class Car
  include Transitions

  state_machine do
    state :parked
    state :driving
    state :switched_off

    event :start_driving do
      transitions from: :parked, to: :driving
    end

    event :switch_off_engine do
      transitions from: :parked, to: :switched_off
    end
  end
end

class TestStateTransitionEventFailedCallback < Test::Unit::TestCase
  def setup
    @car = Car.new
  end

  test "should execute the event_failed_callback and don't raise error if callback is defined" do
    @car.start_driving
    @car.expects(:event_failed).with(:switch_off_engine)
    @car.switch_off_engine
  end

  test "should just re-raise any error on transition if the event_failed_callback isn't defined" do
    @car.start_driving
    assert_raise(Transitions::InvalidTransition) { @car.switch_off_engine }
  end
end
