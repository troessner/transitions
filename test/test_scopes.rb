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
  include ActiveRecord::Transitions

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

class LightBulb < ActiveRecord::Base
  include ActiveRecord::Transitions

  state_machine do
    state :off
    state :on
  end
end

class TestScopes < Test::Unit::TestCase
  test "scope returns correct object" do
    @light = TrafficLight.create!
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

  test 'scopes are only generated if we explicitly say so' do
    assert !LightBulb.respond_to?(:off)
    assert !LightBulb.respond_to?(:on)
  end

  test 'scope generation raises an exception if we try to overwrite an existing method' do
    assert_raise(Transitions::InvalidMethodOverride) {
      class Light < ActiveRecord::Base
        include ActiveRecord::Transitions

        state_machine :auto_scopes => true do
          state :new
          state :broken
        end
      end
    }
  end
end
