require "helper"

class ArgumentsTestSubject
  include Transitions
  attr_accessor :date

  state_machine do
    state :initial
    state :opened

    event :open do
      transitions :from => :initial, :to => :opened, :on_transition => :update_date
    end
  end

  def update_date(date = Date.today)
    self.date = date
  end
end

class StateMachineMachineTest < Test::Unit::TestCase
  test "pass arguments to transition method" do
    subject = ArgumentsTestSubject.new
    assert_equal :initial, subject.current_state
    subject.open!(Date.yesterday)
    assert_equal :opened, subject.current_state
    assert_equal Date.yesterday, subject.date
  end
end

