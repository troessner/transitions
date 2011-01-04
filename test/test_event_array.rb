require "helper"

class EventArrayTestSubject
  include Transitions
  attr_accessor :date, :other_date

  state_machine do
    state :initial
    state :opened

    event :open do
      transitions :from => :initial, :to => :opened, :on_transition => [:update_date, :update_other_date]
    end
  end

  def update_date
    self.date = Date.today
  end
  
  def update_other_date
    self.other_date = Date.today
  end
end

class StateMachineMachineTest < Test::Unit::TestCase
  test "call both methods in transition method array" do
    subject = EventArrayTestSubject.new
    assert_equal :initial, subject.current_state
    subject.open!
    assert_equal :opened, subject.current_state
    assert_equal Date.today, subject.date
    assert_equal Date.today, subject.other_date
  end
end

