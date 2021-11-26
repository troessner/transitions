require 'helper'

# Regression test for https://github.com/troessner/transitions/issues/95
class CreateSwitches < ActiveRecord::Migration[4.2]
  def self.up
    create_table(:switches, force: true) do |t|
      t.string :state
    end
  end
end

class Switch < ActiveRecord::Base
  include ActiveModel::Transitions

  state_machine do
    state :off
    state :on
  end
end

class TestCustomSelect < Test::Unit::TestCase
  def setup
    set_up_db CreateSwitches
    Switch.create!
  end

  test 'should not trigger an exception when we use a custom select query which excludes the name of our state attribute' do
    result = Switch.select(:id)
    assert_nothing_raised NoMethodError do
      result.inspect
    end
  end
end
