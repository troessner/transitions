require "helper"

class CreateBears < ActiveRecord::Migration
  def self.up
    create_table(:bears, :force => true) do |t|
      t.string :state
    end
  end
end

class CreatePuppies < ActiveRecord::Migration
  def self.up
    create_table(:puppies, :force => true) do |t|
      t.string :state
    end
  end
end

class CreateBunnies < ActiveRecord::Migration
  def self.up
    create_table(:bunnies, :force => true) do |t|
      t.string :state
    end
  end
end

set_up_db CreateBunnies, CreatePuppies

class Bunny < ActiveRecord::Base
  #include ActiveModel::Transitions

  include_state_machine
  state_machine :auto_scopes => true do
    state :hobbling
  end
end

class Puppy < ActiveRecord::Base
  #include ActiveModel::Transitions

  include_state_machine
  state_machine do
    state :barking
  end
end

class TestScopes < Test::Unit::TestCase
  def setup
    set_up_db CreateBears, CreateBunnies, CreatePuppies
    @bunny = Bunny.create!
  end

  test "scopes exist" do
    assert_respond_to Bunny, :hobbling
  end

  test "scope returns correct object" do
    assert_equal Bunny.hobbling.first, @bunny
  end

  test 'scopes are only generated if we explicitly say so' do
    assert_not_respond_to Puppy, :barking
  end

  test 'scope generation raises an exception if we try to overwrite an existing method' do
    assert_raise(Transitions::InvalidMethodOverride) {
      class Bear < ActiveRecord::Base
        #include ActiveModel::Transitions

        include_state_machine
        state_machine :auto_scopes => true do
          state :new
        end
      end
    }
  end
end
