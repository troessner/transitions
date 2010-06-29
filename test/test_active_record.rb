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
end
