require "helper"
require 'active_support/core_ext/module/aliasing'

class CreateTrafficLights < ActiveRecord::Migration
  def self.up
    create_table(:traffic_lights) { |t| t.string :state }
  end
end

class TrafficLight < ActiveRecord::Base
  include ActiveRecord::Transitions

  state_machine do
    state :off

    state :red
    state :green
    state :yellow

    event :red_on do
      transitions :to => :red, :from => [:yellow]
    end

    event :green_on do
      transitions :to => :green, :from => [:red]
    end

    event :yellow_on do
      transitions :to => :yellow, :from => [:green]
    end

    event :reset do
      transitions :to => :red, :from => [:off]
    end
  end
end

class ProtectedTrafficLight < TrafficLight
  attr_protected :state
end

class ValidatingTrafficLight < TrafficLight
  validate {|t| errors.add(:base, 'This TrafficLight will never validate after creation') unless t.new_record? }
end

class TestActiveRecord < Test::Unit::TestCase
  def setup
    ActiveRecord::Base.establish_connection(:adapter  => "sqlite3", :database => ":memory:")
    ActiveRecord::Migration.verbose = false
    CreateTrafficLights.migrate(:up)

    @light = TrafficLight.create!
  end

  test "states initial state" do
    assert @light.off?
    assert_equal :off, @light.current_state
  end

  test "transition to a valid state" do
    @light.reset
    assert @light.red?
    assert_equal :red, @light.current_state

    @light.green_on
    assert @light.green?
    assert_equal :green, @light.current_state
  end

  test "transition does not persist state" do
    @light.reset
    assert_equal :red, @light.current_state
    @light.reload
    assert_equal "off", @light.state
  end

  test "transition does persists state" do
    @light.reset!
    assert_equal :red, @light.current_state
    @light.reload
    assert_equal "red", @light.state
  end

  test "transition to an invalid state" do
    assert_raise(Transitions::InvalidTransition) { @light.yellow_on }
    assert_equal :off, @light.current_state
  end

  test "transition does persists state when state is protected" do
    protected_light = ProtectedTrafficLight.create!
    protected_light.reset!
    assert_equal :red, protected_light.current_state
    protected_light.reload
    assert_equal "red", protected_light.state
  end

  test "transition with wrong state will not validate" do
    for s in @light.class.state_machine.states
      @light.state = s.name
      assert @light.valid?
    end
    @light.state = "invalid_one"
    assert_false @light.valid?
  end

  test "transition raises exception when model validation fails" do
    validating_light = ValidatingTrafficLight.create!
    assert_raise(ActiveRecord::RecordInvalid) do
      validating_light.reset!
    end
  end
end
