require "helper"

class Bender
  include Transitions

  state_machine do
    state :drinking
    state :smoking
    state :gambling

    event :cough do
      transitions from: :smoking, to: :gambling
    end
  end
end

class TestAvailableStatesListing < Test::Unit::TestCase
  test 'available_states should return the states for the state machine' do
    assert_equal [:drinking, :gambling, :smoking], Bender.available_states
  end
  test 'available_events should return the events for the state machine' do
    assert_equal [:cough], Bender.available_events
  end
end
