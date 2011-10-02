require "helper"
require 'active_support/core_ext/module/aliasing'

create_database

class Order < ActiveRecord::Base
  include ActiveRecord::Transitions

  state_machine do
    state :opened
    state :placed
    state :paid
    state :prepared
    state :delivered
    state :cancelled
    
    # no timestamp col is being specified here - should be ignored
    event :place do
      transitions :from => :opened, :to => :placed
    end

    # should set paid_at timestamp
    event :pay, :timestamp => true do
      transitions :from => :placed, :to => :paid
    end

    # should set prepared_on
    event :prepare, :timestamp => true do
      transitions :from => :paid, :to => :prepared
    end

    # should set dispatched_at
    event :deliver, :timestamp => :dispatched_at do
      transitions :from => :prepared, :to => :delivered
    end
    
    # should set cancellation_date
    event :cancel, :timestamp => :cancellation_date do
      transitions :from => [:placed, :paid, :prepared], :to => :cancelled
    end
    
    # should raise an exception as there is no timestamp col
    event :reopen, :timestamp => true do
      transitions :from => :cancelled, :to => :opened
    end
    
  end
end


class TestActiveRecordTimestamps < Test::Unit::TestCase
  
  require "securerandom"
  
  def setup
    create_database
  end
  
  def create_order(state = nil)
    Order.create! order_number: SecureRandom.hex(4), state: state
  end

  # control case, no timestamp has been set so we should expect default behaviour
  test "moving to placed does not raise any exceptions" do
    @order = create_order
    assert_nothing_raised { @order.place! }
    assert_equal @order.state, "placed"
  end
  
  test "moving to paid should set paid_at" do
    @order = create_order(:placed)
    @order.pay!
    assert_not_nil @order.paid_at
  end

end
