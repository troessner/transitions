require "helper"

class TestStateTransitionGuardCheck < Test::Unit::TestCase
  args = [:foo, "bar"]

  test "should return true of there is no guard" do
    opts = {:from => "foo", :to => "bar"}
      st = Transitions::StateTransition.new(opts)

    assert st.perform(nil, *args)
  end

  test "should call the method on the object if guard is a symbol" do
    opts = {:from => "foo", :to => "bar", :guard => :test_guard}
    st = Transitions::StateTransition.new(opts)

    obj = stub
    obj.expects(:test_guard).with(*args)

    st.perform(obj, *args)
  end

  test "should call the method on the object if guard is a string" do
    opts = {:from => "foo", :to => "bar", :guard => "test_guard"}
    st = Transitions::StateTransition.new(opts)

    obj = stub
    obj.expects(:test_guard).with(*args)

    st.perform(obj, *args)
  end

  test "should call the proc passing the object if the guard is a proc" do
    opts = {:from => "foo", :to => "bar", :guard => Proc.new {|o, *args| o.test_guard(*args)}}
    st = Transitions::StateTransition.new(opts)

    obj = stub
    obj.expects(:test_guard).with(*args)

    st.perform(obj, *args)
  end
end
