require "helper"

class CreateTrafficLights < ActiveRecord::Migration
  def self.up
    create_table(:traffic_lights, :force => true) do |t|
      t.string :state
      t.string :name
    end
  end
end

set_up_db CreateTrafficLights

class CreateDifferentTrafficLights < ActiveRecord::Migration
  def self.up
    create_table(:different_traffic_lights) do |t|
      t.string :different_state
      t.string :name
    end
  end
end

set_up_db CreateDifferentTrafficLights

class TrafficLight < ActiveRecord::Base
  include ActiveModel::Transitions
  attr_reader :power

  state_machine :auto_scopes => true do
    state :off, enter: :turn_power_on

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

  def turn_power_on
    raise "the power should not have been on already" if @power == :on
    @power = :on
  end
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
    assert_equal "off", @light.state
  end

  test "new active records defaults current state to the initial state" do
    assert_equal :off, @light.current_state
  end

  test "states initial state" do
    assert @light.off?
    assert_equal :off, @light.current_state
  end

  test "calls enter when setting the initial state" do
    @new_light = TrafficLight.new
    assert_equal :on, @new_light.power
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

  test "transition with wrong state will not validate" do
    for s in @light.class.get_state_machine.states
      @light.state = s.name
      assert @light.valid?
    end
    @light.state = "invalid_one"
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
    @light.update_attribute(:state, 'green')
    assert @light.reload.green?, "reloaded state should come from database, not instance variable"
  end
  
  test "calling non-bang event updates state attribute" do
    @light.reset!
    assert @light.red?
    @light.green_on
    assert_equal "green", @light.state
    assert_equal "red", @light.reload.state
  end
end

if ActiveRecord::VERSION::MAJOR == 3
  class ProtectedTrafficLight < TrafficLight
    attr_protected :state
  end

  class TestMassAssignmentActiveRecord < TestActiveRecord
    test "transition does persists state when state is protected" do
      protected_light = ProtectedTrafficLight.create!
      protected_light.reset!
      assert_equal :red, protected_light.current_state
      protected_light.reload
      assert_equal "red", protected_light.state
    end
  end
end

class TestNewActiveRecord < TestActiveRecord

  def setup
    set_up_db CreateTrafficLights
    @light = TrafficLight.new
  end

  test "new active records defaults current state to the initial state" do
    assert_equal :off, @light.current_state
  end

end

class TestScopes < Test::Unit::TestCase
  test "scope returns correct object" do
    @light = TrafficLight.create!
    assert_respond_to TrafficLight, :off
    assert_equal TrafficLight.off.first, @light
    assert TrafficLight.red.empty?
  end

  test "scopes exist" do
    assert_respond_to TrafficLight, :off
    assert_respond_to TrafficLight, :red
    assert_respond_to TrafficLight, :green
    assert_respond_to TrafficLight, :yellow
  end

  test 'scopes are only generated if we explicitly say so' do
    assert_not_respond_to LightBulb, :off
    assert_not_respond_to LightBulb, :on
  end

  test 'scope generation raises an exception if we try to overwrite an existing method' do
    assert_raise(Transitions::InvalidMethodOverride) {
      class Light < ActiveRecord::Base
        include ActiveModel::Transitions

        state_machine :auto_scopes => true do
          state :new
          state :broken
        end
      end
    }
  end
end

class DifferentTrafficLight < ActiveRecord::Base
  include ActiveModel::Transitions

  state_machine :attribute_name => :different_state, :auto_scopes => true do
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

class TestActiveRecordWithDifferentColumnName < Test::Unit::TestCase
  def setup
    set_up_db CreateDifferentTrafficLights
    @light = DifferentTrafficLight.create!
  end

  test "new record has the initial state set" do
    @light = DifferentTrafficLight.new
    assert_equal "off", @light.different_state
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
    assert_equal "off", @light.different_state
  end

  test "transition does persists state" do
    @light.reset!
    assert_equal :red, @light.current_state
    @light.reload
    assert_equal "red", @light.different_state
  end

  test "transition to an invalid state" do
    assert_raise(Transitions::InvalidTransition) { @light.yellow_on }
    assert_equal :off, @light.current_state
  end

  test "transition with wrong state will not validate" do
    for s in @light.class.state_machine.states
      @light.different_state = s.name
      assert @light.valid?
    end
    @light.different_state = "invalid_one"
    assert_false @light.valid?
  end

  test "reloading model resets current state" do
    @light.reset
    assert @light.red?
    @light.update_attribute(:different_state, 'green')
    assert @light.reload.green?, "reloaded state should come from database, not instance variable"
  end
  
  test "calling non-bang event updates state attribute" do
    @light.reset!
    assert @light.red?
    @light.green_on
    assert_equal "green", @light.different_state
    assert_equal "red", @light.reload.different_state
  end
end
