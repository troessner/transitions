require "helper"

class TestStateTransition < Test::Unit::TestCase
  test "should set from, to, and opts attr readers" do
    opts = {:from => "foo", :to => "bar", :guard => "g"}
    st = Transitions::StateTransition.new(opts)

    assert_equal opts[:from], st.from
    assert_equal opts[:to],   st.to
    assert_equal opts,        st.options
  end

  test "should pass equality check if from and to are the same" do
    opts = {:from => "foo", :to => "bar", :guard => "g"}
    st = Transitions::StateTransition.new(opts)

    obj = stub
    obj.stubs(:from).returns(opts[:from])
    obj.stubs(:to).returns(opts[:to])

    assert_equal st, obj
  end

  test "should fail equality check if from are not the same" do
    opts = {:from => "foo", :to => "bar", :guard => "g"}
    st = Transitions::StateTransition.new(opts)

    obj = stub
    obj.stubs(:from).returns("blah")
    obj.stubs(:to).returns(opts[:to])

    assert_not_equal st, obj
  end

  test "should fail equality check if to are not the same" do
    opts = {:from => "foo", :to => "bar", :guard => "g"}
    st = Transitions::StateTransition.new(opts)

    obj = stub
    obj.stubs(:from).returns(opts[:from])
    obj.stubs(:to).returns("blah")

    assert_not_equal st, obj
  end
end
