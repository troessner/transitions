require 'helper'

class TestState < Test::Unit::TestCase
  def setup
    machine = Class.new do
      include Transitions
      state_machine do
      end
    end.state_machine
    state_name = :astate
    @options = { machine: machine, custom_key: :my_key }
    @state   = Transitions::State.new(state_name, @options)
  end

  def new_state_name
    Random.alphanumeric(16)
  end

  test 'sets the name' do
    assert_equal :astate, @state.name
  end

  test 'sets the display_name from name' do
    assert_equal 'Astate', @state.display_name
  end

  test 'sets the display_name from options' do
    assert_equal 'A State', Transitions::State.new(new_state_name, @options.merge(display: 'A State')).display_name
  end

  test 'sets the options and expose them as options' do
    @options.delete(:machine)
    state = Transitions::State.new new_state_name, @options
    assert_equal @options, state.options
  end

  test 'equals a symbol of the same name' do
    assert_equal @state, :astate
  end

  test 'equals a State of the same name' do
    assert_equal @state, @state
  end

  test 'should send a message to the record for an action if the action is present as a symbol' do
    state = Transitions::State.new new_state_name, @options.merge(entering: :foo)

    record = stub
    record.expects(:foo)

    state.call_action(:entering, record)
  end

  test 'should send a message to the record for an action if the action is present as a string' do
    state = Transitions::State.new new_state_name, @options.merge(entering: 'foo')

    record = stub
    record.expects(:foo)

    state.call_action(:entering, record)
  end

  test 'should call a proc, passing in the record for an action if the action is present' do
    state = Transitions::State.new new_state_name, @options.merge(entering: proc(&:foobar))

    record = stub
    record.expects(:foobar)

    state.call_action(:entering, record)
  end
end
