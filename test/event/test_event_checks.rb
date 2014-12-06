require 'helper'

class ChecksTestSubject
  include Transitions

  state_machine initial: :initial do
    state :initial
    state :opened
    state :closed

    event :open do
      transitions from: :initial, to: :opened
    end

    event :close do
      transitions from: :opened, to: :closed
    end
  end
end

class StateMachineChecksTest < Test::Unit::TestCase
  test 'checks if a given transition is possible' do
    subject = ChecksTestSubject.new
    assert_equal :initial, subject.current_state
    assert_equal true, subject.can_open?
    assert_equal false, subject.can_close?

    subject.open

    assert_equal false, subject.can_open?
    assert_equal true, subject.can_close?
  end
end
