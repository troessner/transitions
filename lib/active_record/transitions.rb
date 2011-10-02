# Copyright (c) 2009 Rick Olson

# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

module ActiveRecord
  
  # Extend ActiveRecord with a Transitions module which should be included in each
  # class that behaves as a state machine
  module Transitions
    extend ActiveSupport::Concern

    included do
      include ::Transitions
      after_initialize :set_initial_state
      validates_presence_of :state
      validate :state_inclusion
    end
    
    # The optional options argument is passed to find when reloading so you may
    # do e.g. record.reload(:lock => true) to reload the same record with an
    # exclusive row lock. 
    def reload(options = nil)
      super.tap do
        self.class.state_machines.values.each do |sm|
          remove_instance_variable(sm.current_state_variable) if instance_variable_defined?(sm.current_state_variable)
        end
      end
    end

    protected

    # Write the new state of this record and save!
    def write_state(state_machine, state)
      ivar = state_machine.current_state_variable
      prev_state = current_state(state_machine.name)
      instance_variable_set(ivar, state)
      self.state = state.to_s
      save!
    rescue ActiveRecord::RecordInvalid
      self.state = prev_state.to_s
      instance_variable_set(ivar, prev_state)
      raise
    end
    
    def read_state(state_machine)
      self.state && self.state.to_sym
    end

    # Set the initial state of this record to state_machine's initial state unless it's 
    # already been defined
    def set_initial_state
      self.state ||= self.class.state_machine.initial_state.to_s if self.has_attribute?(:state)
    end

    # If the current state is not defined within the state_machine, mark as invalid
    def state_inclusion
      unless self.class.state_machine.states.map{|s| s.name.to_s }.include?(self.state.to_s)
        self.errors.add(:state, :inclusion, :value => self.state)
      end
    end
  end
end

