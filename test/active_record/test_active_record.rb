require "helper"

class CreateTrafficLights < ActiveRecord::Migration
  def self.up
    create_table(:traffic_lights, :force => true) do |t|
      t.string :transitions_state
      t.string :name
    end
  end
end

set_up_db CreateTrafficLights

class TrafficLight < ActiveRecord::Base
  #include ActiveModel::Transitions

  include_state_machine
  state_machine :auto_scopes => true, :state_column => :transitions_state do
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
  attr_protected :transitions_state
end

class ValidatingTrafficLight < TrafficLight
  validate {|t| errors.add(:base, 'This TrafficLight will never validate after creation') unless t.new_record? }
end

class ConditionalValidatingTrafficLight < TrafficLight
  validates(:name, :presence => true, :if => :red?)
end

class TestActiveRecord < Test::Unit::TestCase
  def setup
    set_up_db CreateTrafficLights
    @light = TrafficLight.create!
  end

  test "new record has the initial state set" do
    @light = TrafficLight.new
    assert_equal "off", @light.transitions_state
  end

  test "new active records defaults current state to the initial state" do
    assert_equal :off, @light.current_state
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
    assert_equal "off", @light.transitions_state
  end

  test "transition does persists state" do
    @light.reset!
    assert_equal :red, @light.current_state
    @light.reload
    assert_equal "red", @light.transitions_state
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
    assert_equal "red", protected_light.transitions_state
  end

  test "transition with wrong state will not validate" do
    for s in @light.class.get_state_machine.states
      @light.transitions_state = s.name
      assert @light.valid?
    end
    @light.transitions_state = "invalid_one"
    assert_false @light.valid?
  end

  test "transition raises exception when model validation fails" do
    validating_light = ValidatingTrafficLight.create!(:name => 'Foobar')
    assert_raise(ActiveRecord::RecordInvalid) do
      validating_light.reset!
    end
  end

  test "state query method used in a validation condition" do
    validating_light = ConditionalValidatingTrafficLight.create!
    assert_raise(ActiveRecord::RecordInvalid) do
      validating_light.reset!
    end
    assert(validating_light.off?)
  end

  test "reloading model resets current state" do
    @light.reset
    assert @light.red?
    @light.update_attribute(:transitions_state, 'green')
    assert @light.reload.green?, "reloaded state should come from database, not instance variable"
  end
  
  test "calling non-bang event updates state attribute" do
    @light.reset!
    assert @light.red?
    @light.green_on
    assert_equal "green", @light.transitions_state
    assert_equal "red", @light.reload.transitions_state
  end
end
