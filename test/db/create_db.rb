# Use this schema to create all required tables
class CreateDb < ActiveRecord::Migration
  def self.up
    create_table(:traffic_lights, :force => true) do |t|
      t.string :state
      t.string :name
    end
    
    create_table(:orders, :force => true) do |t|
      t.string :state
      t.string :order_number
      t.datetime :paid_at
      t.datetime :prepared_on
      t.datetime :dispatched_at 
      t.date :cancellation_date
    end
    
  end
end
