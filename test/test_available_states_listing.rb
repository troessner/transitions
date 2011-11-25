require "helper"

class Bender
  include Transitions

  state_machine :default do
    state :drinking
    state :smoking
    state :gambling
  end

  state_machine :maintenance do
    state :wip
    state :finished
  end
end

class TestAvailableStatesListing < Test::Unit::TestCase
  test 'available_states should return the states for the default state machine if no state machine is specified' do
    assert_equal [:drinking, :gambling, :smoking], Bender.available_states
  end

  test 'available_states should return the states for a given state' do
    assert_equal [:finished, :wip], Bender.available_states(:maintenance)
    assert_equal [:drinking, :gambling, :smoking], Bender.available_states(:default)
  end
end
