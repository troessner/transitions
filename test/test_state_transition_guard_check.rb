require "helper"

class TestStateTransitionGuardCheck < Test::Unit::TestCase
  test "should return true of there is no guard" do
    opts = {:from => "foo", :to => "bar"}
      st = Transitions::StateTransition.new(opts)

    assert st.perform(nil)
  end

  test "should call the method on the object if guard is a symbol" do
    opts = {:from => "foo", :to => "bar", :guard => :test_guard}
    st = Transitions::StateTransition.new(opts)

    obj = stub
    obj.expects(:test_guard)

    st.perform(obj)
  end

  test "should call the method on the object if guard is a string" do
    opts = {:from => "foo", :to => "bar", :guard => "test_guard"}
    st = Transitions::StateTransition.new(opts)

    obj = stub
    obj.expects(:test_guard)

    st.perform(obj)
  end

  test "should call the proc passing the object if the guard is a proc" do
    opts = {:from => "foo", :to => "bar", :guard => Proc.new {|o| o.test_guard}}
    st = Transitions::StateTransition.new(opts)

    obj = stub
    obj.expects(:test_guard)

    st.perform(obj)
  end
end
