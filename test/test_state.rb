require "helper"

class TestState < Test::Unit::TestCase
  def setup
    @state_test_subject = Class.new do
      include Transitions
      state_machine do
      end
    end
    @state_name = :astate
    @machine = @state_test_subject.state_machine
    @options = { :machine => @machine, :custom_key => :my_key }
    @state   = Transitions::State.new(@state_name, @options)
  end

  def new_state_name
    Random.alphanumeric(16)
  end

  test "sets the name" do
    assert_equal :astate, @state.name
  end

  test "sets the display_name from name" do
    assert_equal "Astate", @state.display_name
  end

  test "sets the display_name from options" do
    assert_equal "A State", Transitions::State.new(new_state_name, @options.merge(:display => "A State")).display_name
  end

  test "sets the options and expose them as options" do
    @options.delete(:machine)
    state = Transitions::State.new new_state_name, @options
    assert_equal @options, state.options
  end

  test "equals a symbol of the same name" do
    assert_equal @state, :astate
  end

  test "equals a State of the same name" do
    assert_equal @state, @state
  end

  test "should send a message to the record for an action if the action is present as a symbol" do
    state = Transitions::State.new new_state_name, @options.merge(:entering => :foo)

    record = stub
    record.expects(:foo)

    state.call_action(:entering, record)
  end

  test "should send a message to the record for an action if the action is present as a string" do
    state = Transitions::State.new new_state_name, @options.merge(:entering => "foo")

    record = stub
    record.expects(:foo)

    state.call_action(:entering, record)
  end

  test "should call a proc, passing in the record for an action if the action is present" do
    state = Transitions::State.new new_state_name, @options.merge(:entering => Proc.new {|r| r.foobar})

    record = stub
    record.expects(:foobar)

    state.call_action(:entering, record)
  end
end

class StateOverrideMethodTestSubject
  include Transitions

  state_machine do
  end

  def a_state_name?; :foo; end
end


class TestStateQueryOverrideMethod < Test::Unit::TestCase
  def setup
    @state_name = 'a_state_name'
    @machine = StateOverrideMethodTestSubject.state_machine
    @options = { :machine => @machine }
  end

  test "warn on creation when we try to overwrite an existing method" do
    # TODO
  end

  test "should not override an already existing method" do
    Transitions::State.new :dummy, @options
    expected_result = :foo
    actual_result   = StateOverrideMethodTestSubject.new.a_state_name?
    assert_equal expected_result, actual_result
  end
end
