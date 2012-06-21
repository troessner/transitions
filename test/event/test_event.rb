require "helper"

class TestEvent < Test::Unit::TestCase
  def setup
    @state_name = :close_order
    @success_as_symbol = :success_callback
    @success_as_lambda = lambda { |record| record.success_callback }
  end

  def event_with_symbol_success_callback
    @event = Transitions::Event.new(nil, @state_name, {:success => @success_as_symbol}) do
      transitions :to => :closed, :from => [:open, :received]
    end
  end
  alias_method :new_event, :event_with_symbol_success_callback

  def event_with_lambda_success_callback
    @event = Transitions::Event.new(nil, @state_name, {:success => @success_as_lambda}) do
      transitions :to => :closed, :from => [:open, :received]
    end
  end

  test "should set the name" do
    assert_equal @state_name, new_event.name
  end

  test "should set the success callback with a symbol and return a block" do
    assert_respond_to event_with_symbol_success_callback.success, :call
  end

  test "should build a block which calls the given success_callback symbol on the passed record instance" do
    record = mock("SomeRecordToGetCalled")
    record.expects(:success_callback)

    event_with_symbol_success_callback.success.call(record)
  end

  test "should set the success callback with a lambda" do
    assert_respond_to event_with_lambda_success_callback.success, :call
  end

  test "should create StateTransitions" do
    Transitions::StateTransition.expects(:new).with(:to => :closed, :from => :open)
    Transitions::StateTransition.expects(:new).with(:to => :closed, :from => :received)
    new_event
  end
end
