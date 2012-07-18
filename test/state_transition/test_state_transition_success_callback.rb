require 'helper'

class DrivingInstructor
  def self.applause!
  end
end

class DrivingSchoolCar
  #include Transitions
  include Transitions::ActiveRecordExtension

  include_state_machine
  state_machine do
    state :parked
    state :running
    state :driving
    state :switched_off

    event :start_driving, :success => lambda { |car| DrivingInstructor.applause! } do
      transitions :from => :parked, :to => :driving, :on_transition => [:start_engine, :loosen_handbrake, :push_gas_pedal]
    end

    event :switch_off_engine do
      transitions :from => :parked, :to => :switched_off
    end
  end

  %w!start_engine loosen_handbrake push_gas_pedal!.each do |m|
    define_method(m){}
  end
end

class TestStateTransitionSuccessCallback < Test::Unit::TestCase
  def setup
    @car = DrivingSchoolCar.new
  end

  test "should execute the success callback after successfull event execution" do
    DrivingInstructor.expects(:applause!)

    @car.start_driving!
  end

  test "should not execute the success callback after event execution failed" do
    DrivingInstructor.expects(:applause!).never

    @car.stubs(:event_failed)
    @car.expects(:loosen_handbrake).raises("Drive with handbrake fail!")
    @car.start_driving!
  end
end
