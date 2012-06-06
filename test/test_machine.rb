require "helper"

class MachineTestSubject
  include Transitions

  state_machine :initial => :closed do
    state :open
    state :closed

    event :shutdown do
      transitions :from => :open, :to => :closed
    end

    event :timeout do
      transitions :from => :open, :to => :closed
    end
  end
end

class TransitionsMachineTest < Test::Unit::TestCase
  test "sets #initial_state from :initial option" do
    assert_equal :closed, MachineTestSubject.get_state_machine.initial_state
  end

  test "`get_state_machine` returns Transitions::Machine" do
    assert_kind_of Transitions::Machine, MachineTestSubject.get_state_machine
  end

  test "finds events for given state" do
    events = MachineTestSubject.get_state_machine.events_for(:open)
    assert events.include?(:shutdown)
    assert events.include?(:timeout)
  end
end
