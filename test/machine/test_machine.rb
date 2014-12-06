require 'helper'

class MachineTestSubject
  include Transitions

  state_machine initial: :closed do
    state :open
    state :closed

    event :shutdown do
      transitions from: :open, to: :closed
    end

    event :timeout do
      transitions from: :open, to: :closed
    end

    event :restart do
      transitions from: :closed, to: :open, guard: :restart_allowed?
    end
  end

  def restart_allowed?(allowed = true)
    allowed
  end
end

class TransitionsMachineTest < Test::Unit::TestCase
  test 'sets #initial_state from :initial option' do
    assert_equal :closed, MachineTestSubject.get_state_machine.initial_state
  end

  test '`get_state_machine` returns Transitions::Machine' do
    assert_kind_of Transitions::Machine, MachineTestSubject.get_state_machine
  end

  test 'finds events for given state' do
    events = MachineTestSubject.get_state_machine.events_for(:open)
    assert events.include?(:shutdown)
    assert events.include?(:timeout)
  end

  test 'knows all available transitions for current state' do
    machine = MachineTestSubject.new
    assert_equal [:restart], machine.available_transitions
    machine.restart
    assert_equal [:shutdown, :timeout], machine.available_transitions
  end

  test 'knows that it can use a transition when it is available' do
    machine = MachineTestSubject.new
    machine.restart
    assert machine.can_transition?(:shutdown)
  end

  test "knows that it can't use a transition when it is unavailable" do
    machine = MachineTestSubject.new
    assert machine.cant_transition?(:shutdown)
  end

  test "knows that it can't transition to a state denied by a guard" do
    machine = MachineTestSubject.new
    assert machine.can_execute_restart? true
    refute machine.can_execute_restart? false
  end
end
