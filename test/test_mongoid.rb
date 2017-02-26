require "helper_mongodb"

class MongoTrafficLight
  include Mongoid::Document
  include Mongoid::Transitions
  field :state

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

class MongoProtectedTrafficLight < TrafficLight
  attr_protected :state
end

class MongoValidatingTrafficLight < MongoTrafficLight
  validate {|t| errors.add(:base, 'This TrafficLight will never validate after creation') unless t.new_record? }
end

class TestMongoid < Test::Unit::TestCase
  def setup
    Mongoid.master.collections.reject { |c| c.name =~ /^system\./ }.each(&:drop)
    @light = MongoTrafficLight.create!
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
    protected_light = MongoProtectedTrafficLight.create!
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
    validating_light = MongoValidatingTrafficLight.create!
    assert_raise(Mongoid::Errors::Validations) do
      validating_light.reset!
    end
  end
end

