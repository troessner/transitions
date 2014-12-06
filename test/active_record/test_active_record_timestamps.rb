require 'helper'

class CreateOrders < ActiveRecord::Migration
  def self.up
    create_table(:orders, force: true) do |t|
      t.string :state
      t.string :order_number
      t.datetime :paid_at
      t.datetime :prepared_on
      t.datetime :dispatched_at
      t.date :cancellation_date
      t.boolean :allow_transition, default: true
    end
  end
end

class Order < ActiveRecord::Base
  include ActiveModel::Transitions

  state_machine do
    state :opened
    state :placed
    state :paid
    state :prepared
    state :delivered
    state :cancelled

    # no timestamp col is being specified here - should be ignored
    event :place do
      transitions from: :opened, to: :placed
    end

    # should set paid_at timestamp
    event :pay, timestamp: true do
      transitions from: :placed, to: :paid, guard: lambda { |obj| obj.allow_transition }
    end

    # should set prepared_on
    event :prepare, timestamp: true do
      transitions from: :paid, to: :prepared
    end

    # should set dispatched_at
    event :deliver, timestamp: 'dispatched_at' do
      transitions from: :prepared, to: :delivered
    end

    # should set cancellation_date
    event :cancel, timestamp: :cancellation_date do
      transitions from: [:placed, :paid, :prepared], to: :cancelled
    end

    # should raise an exception as there is no timestamp col
    event :reopen, timestamp: true do
      transitions from: :cancelled, to: :opened
    end
  end
end

class TestActiveRecordTimestamps < Test::Unit::TestCase
  require 'securerandom'

  def setup
    set_up_db CreateOrders
  end

  def create_order(state = nil)
    Order.create! order_number: SecureRandom.hex(4), state: state
  end

  # control case, no timestamp has been set so we should expect default behaviour
  test 'moving to placed does not raise any exceptions' do
    @order = create_order
    assert_nothing_raised { @order.place! }
    assert_equal @order.state, 'placed'
  end

  test 'moving to paid should set paid_at' do
    @order = create_order(:placed)
    @order.pay!
    @order.reload
    assert_not_nil @order.paid_at
  end

  test 'moving to paid should not set paid_at if our guard evaluates to false' do
    @order = create_order(:placed)
    @order.update_attribute :allow_transition, false
    @order.pay!
    @order.reload
    assert_nil @order.paid_at
  end

  test 'moving to prepared should set prepared_on' do
    @order = create_order(:paid)
    @order.prepare!
    @order.reload
    assert_not_nil @order.prepared_on
  end

  test 'moving to delivered should set dispatched_at' do
    @order = create_order(:prepared)
    @order.deliver!
    @order.reload
    assert_not_nil @order.dispatched_at
  end

  test 'moving to cancelled should set cancellation_date' do
    @order = create_order(:placed)
    @order.cancel!
    @order.reload
    assert_not_nil @order.cancellation_date
  end

  test 'moving to reopened should raise an exception as there is no attribute' do
    @order = create_order(:cancelled)
    assert_raise(NoMethodError) { @order.re_open! }
    @order.reload
  end

  test 'passing an invalid value to timestamp options should raise an exception' do
    assert_raise(ArgumentError) do
      class Order < ActiveRecord::Base
        include ActiveModel::Transitions
        state_machine do
          event :replace, timestamp: 1 do
            transitions from: :prepared, to: :placed
          end
        end
      end
    end
  end
end
