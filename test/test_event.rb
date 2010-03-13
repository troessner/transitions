require "helper"

class TestEvent < Test::Unit::TestCase
  def setup
    @state_name = :close_order
    @success = :success_callback
  end

  def new_event
    @event = Transitions::Event.new(nil, @state_name, {:success => @success}) do
      transitions :to => :closed, :from => [:open, :received]
    end
  end

  test "should set the name" do
    assert_equal @state_name, new_event.name
  end

  test "should set the success option" do
    assert_equal @success, new_event.success
  end

  test "should create StateTransitions" do
    Transitions::StateTransition.expects(:new).with(:to => :closed, :from => :open)
    Transitions::StateTransition.expects(:new).with(:to => :closed, :from => :received)
    new_event
  end
end
