require 'helper'

class TestStateTransitionGuardCheck < Test::Unit::TestCase
  args = [:foo, 'bar']

  test 'should return true of there is no guard' do
    opts = { from: 'foo', to: 'bar' }
    st = Transitions::StateTransition.new(opts)

    assert st.executable?(nil, *args)
  end

  test 'should call the method on the object if guard is a symbol' do
    opts = { from: 'foo', to: 'bar', guard: :test_guard }
    st = Transitions::StateTransition.new(opts)

    obj = stub
    obj.expects(:test_guard).with(*args)

    st.executable?(obj, *args)
  end

  test 'should call the method on the object if guard is a string' do
    opts = { from: 'foo', to: 'bar', guard: 'test_guard' }
    st = Transitions::StateTransition.new(opts)

    obj = stub
    obj.expects(:test_guard).with(*args)

    st.executable?(obj, *args)
  end

  test 'should call the proc passing the object if the guard is a proc' do
    opts = { from: 'foo', to: 'bar', guard: proc { |o, *args| o.test_guard(*args) } }
    st = Transitions::StateTransition.new(opts)

    obj = stub
    obj.expects(:test_guard).with(*args)

    st.executable?(obj, *args)
  end

  test 'should call the callable passing the object if the guard responds to #call' do
    callable = Object.new
    callable.define_singleton_method(:call) { |obj, *args| obj.test_guard(*args) }

    opts = { from: 'foo', to: 'bar', guard: callable }
    st = Transitions::StateTransition.new(opts)

    obj = stub
    obj.expects(:test_guard).with(*args)

    st.executable?(obj, *args)
  end

  test 'should call the method on the object if guard is a symbol' do
    opts = { from: 'foo', to: 'bar', guard: [:test_guard, :test_another_guard] }
    st = Transitions::StateTransition.new(opts)

    obj = stub
    obj.expects(:test_guard).with(*args).returns(true)
    obj.expects(:test_another_guard).with(*args).returns(true)

    assert st.executable?(obj, *args)
  end
end
