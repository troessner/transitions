require "helper"

class Bus
  include Transitions::Extension
  EXISTING_PREDICATE_METHOD_NAME = :driving?
  EXISTING_PREDICATE_METHOD_RETURN_VALUE = 'Am I driving?'

  include_state_machine
  state_machine do
    state :parking
    state :driving
  end

  def driving?; EXISTING_PREDICATE_METHOD_RETURN_VALUE; end
end

class TestStatePredicateMethod < Test::Unit::TestCase
  def setup
    @bus = Bus.new
  end

  test "should generate predicate methods for states" do
    assert_true @bus.respond_to?(:parking?)
    assert_true @bus.send(:parking?)
  end

  test "warn on creation when we try to overwrite an existing method" do
    pend 'Implement me'
  end

  test "should not override an already existing method" do
    expected_result = Bus::EXISTING_PREDICATE_METHOD_RETURN_VALUE
    actual_result   = @bus.send Bus::EXISTING_PREDICATE_METHOD_NAME
    assert_equal expected_result, actual_result
  end
end
