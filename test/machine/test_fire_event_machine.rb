require 'helper'
require_relative './machine_template'

class TestFireEventMachine < Test::Unit::TestCase
  def setup
    @record  = MachineTestSubject.new
    @machine = MachineTestSubject.get_state_machine
    @event   = @machine.events_for(@record.current_state).first
    assert_not_nil @event
  end

  test 'fire_event returns true if state transition was successful' do
    @machine.stubs(:transition_to_new_state).returns(:closed)

    assert_equal true, @machine.fire_event(@event, @record, false)
  end

  test 'fire_event returns false if state transition was unsuccessful' do
    @machine.stubs(:transition_to_new_state).returns(false)

    assert_equal false, @machine.fire_event(@event, @record, false)
  end

  test 'fire_event returns false if state transition raises' do
    @machine.stubs(:transition_to_new_state).raises(StandardError)

    assert_equal false, @machine.fire_event(@event, @record, false)
  end
end
