require "helper"

# Regressiontest for https://github.com/troessner/transitions/issues/95
# TODO We use this Trafficlight class quite a lot in our specs including a ton of duplication.
#      Unify class and migration definition in one place and then clean up all related specs, including this one.
class CreateTrafficLights < ActiveRecord::Migration
  def self.up
    create_table(:traffic_lights, :force => true) do |t|
      t.string :state
      t.string :name
    end
  end
end

class TrafficLight < ActiveRecord::Base
  include ActiveModel::Transitions

  state_machine do
    state :off
    state :on
  end
end

class TestCustomSelect < Test::Unit::TestCase
  def setup
    set_up_db CreateTrafficLights
    @light = TrafficLight.create!
  end

  test "should not trigger an exception when we use a custom select query which excludes the name of our state attribute" do
    result = TrafficLight.select("id, name")
    assert_nothing_raised NoMethodError do
      result.inspect
    end
  end
end
