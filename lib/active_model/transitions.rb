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

module ActiveModel
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
        sm = self.class.get_state_machine
        remove_instance_variable(sm.current_state_variable) if instance_variable_defined?(sm.current_state_variable)
      end
    end

    protected

    def write_state(state)
      prev_state = current_state
      write_state_without_persistence(state)
      save!
    rescue ActiveRecord::RecordInvalid
      write_state_without_persistence(prev_state)
      raise
    end
    
    def write_state_without_persistence(state)
      ivar = self.class.get_state_machine.current_state_variable
      instance_variable_set(ivar, state)
      self.state = state.to_s
    end

    def read_state
      self.state && self.state.to_sym
    end

    def set_initial_state
      self.state ||= self.class.get_state_machine.initial_state.to_s if self.respond_to?(:state=)
    end

    def state_inclusion
      unless self.class.get_state_machine.states.map{|s| s.name.to_s }.include?(self.state.to_s)
        self.errors.add(:state, :inclusion, :value => self.state)
      end
    end
  end
end

