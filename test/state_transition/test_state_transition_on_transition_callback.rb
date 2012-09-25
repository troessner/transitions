require 'helper'

class Truck
  include Transitions
  attr_reader :test_recorder

  def initialize
    @test_recorder = []
  end

  state_machine do
    state :parked
    state :running
    state :driving

    event :turn_key do
      transitions :from => :parked, :to => :running, :on_transition => :start_engine
    end

    event :start_driving do
      transitions :from => :parked, :to => :driving, :on_transition => [:start_engine, :loosen_handbrake, :push_gas_pedal]
    end
  end

  %w!start_engine loosen_handbrake push_gas_pedal!.each do |m|
    define_method(m){ @test_recorder << m }
  end
end

class TestStateTransitionCallbacks < Test::Unit::TestCase
  test "should execute callback defined via 'on_transition'" do
    truck = Truck.new
    truck.expects(:start_engine)
    truck.turn_key!
  end

  test "should execute multiple callbacks defined via 'on_transition' in the same order they were defined" do
    # This test requires some explanation: We started out with something like this:
    #   truck.expects(:start_engine).in_sequence(on_transition_sequence)
    # Which, after a while (don't ask me why) caused some weird problems and seemed to fail randomly.
    # Hence the workaround below.

    truck = Truck.new

    truck.start_driving!
    assert_equal truck.test_recorder, [:start_engine, :loosen_handbrake, :push_gas_pedal].map(&:to_s)
  end
end
