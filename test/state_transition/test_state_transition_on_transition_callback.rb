require 'helper'

class Car
  #include Transitions
  include Transitions::ActiveRecordExtension

  include_state_machine
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
    define_method(m){}
  end
end

class TestStateTransitionCallbacks < Test::Unit::TestCase
  def setup
    @car = Car.new
  end

  test "should execute callback defined via 'on_transition'" do
    @car.expects(:start_engine)
    @car.turn_key!
  end

  test "should execute multiple callbacks defined via 'on_transition' in the same order they were defined" do
    on_transition_sequence = sequence('on_transition_sequence')

    @car.expects(:start_engine).in_sequence(on_transition_sequence)
    @car.expects(:loosen_handbrake).in_sequence(on_transition_sequence)
    @car.expects(:push_gas_pedal).in_sequence(on_transition_sequence)
    @car.start_driving!
  end
end
