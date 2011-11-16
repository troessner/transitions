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

CreateTrafficLights.migrate(:up)

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

class TestScopes < Test::Unit::TestCase
  def setup
    @light = TrafficLight.create!
  end

  test "scope returns correct object" do
    assert TrafficLight.respond_to? :off
    assert_equal TrafficLight.off.first, @light
    assert TrafficLight.red.empty?
  end

  test "scopes exist" do
    assert TrafficLight.respond_to? :off
    assert TrafficLight.respond_to? :red
    assert TrafficLight.respond_to? :green
    assert TrafficLight.respond_to? :yellow
  end
end
