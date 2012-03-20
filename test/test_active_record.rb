require "helper"
require 'active_support/core_ext/module/aliasing'

ActiveRecord::Base.establish_connection(:adapter  => "sqlite3", :database => ":memory:")

class CreateTrafficLights < ActiveRecord::Migration
  def self.up
    create_table(:traffic_lights) do |t|
      t.string :state
      t.string :name
    end
  end
end

class CreateLightBulbs < ActiveRecord::Migration
  def self.up
    create_table(:light_bulbs) do |t|
      t.string :state
    end
  end
end

class CreateLights < ActiveRecord::Migration
  def self.up
    create_table(:lights) do |t|
      t.string :state
    end
  end
end

CreateTrafficLights.migrate(:up)
CreateLightBulbs.migrate(:up)
CreateLights.migrate(:up)

class TrafficLight < ActiveRecord::Base
  include ActiveModel::Transitions

  state_machine :auto_scopes => true do
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

class ConditionalValidatingTrafficLight < TrafficLight
  validates(:name, :presence => true, :if => :red?)
end

class LightBulb < ActiveRecord::Base
  include ActiveModel::Transitions

  state_machine do
    state :off
    state :on
  end
end

class TestActiveRecord < Test::Unit::TestCase
  def setup
    create_database
    @light = TrafficLight.create!
  end

  test "new record has the initial state set" do
    @light = TrafficLight.new
    assert_equal "off", @light.state
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

end

class TestNewActiveRecord < TestActiveRecord

  def setup
    create_database
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
