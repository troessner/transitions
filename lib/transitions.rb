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

require "transitions/event"
require "transitions/machine"
require "transitions/state"
require "transitions/state_transition"
require "transitions/version"

module Transitions
  
  
  # # Exception raised when attempting to perform a transition which has not been defined
  class InvalidTransition < StandardError;end

  module ClassMethods
    def inherited(klass)
      super
      klass.state_machines = state_machines
    end

    def state_machines
      @state_machines ||= {}
    end

    def state_machines=(value)
      @state_machines = value ? value.dup : nil
    end

    def state_machine(name = nil, options = {}, &block)
      if name.is_a?(Hash)
        options = name
        name    = nil
      end
      name ||= :default
      state_machines[name] ||= Machine.new(self, name)
      block ? state_machines[name].update(options, &block) : state_machines[name]
    end

    # defines a query method for each defined state
    # eg. @order.paid? # => true/false
    def define_state_query_method(state_name)
      name = "#{state_name}?"
      undef_method(name) if method_defined?(name)
      class_eval "def #{name}; current_state.to_s == %(#{state_name}) end"
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  # Returns the current state of an instance or sets a new state
  # TODO: This method is Yuck. Should be broken down into simpler parts IMO (@bodacious)
  def current_state(name = nil, new_state = nil, persist = false)
    sm   = self.class.state_machine(name)
    ivar = sm.current_state_variable
    if name && new_state
      if persist && respond_to?(:write_state)
        write_state(sm, new_state)
      end

      # DELETE: I can't see this method defined in this lib...
      # should this code still be here?
      if respond_to?(:write_state_without_persistence)
        write_state_without_persistence(sm, new_state)
      end

      instance_variable_set(ivar, new_state)
    else
      instance_variable_set(ivar, nil) unless instance_variable_defined?(ivar)
      value = instance_variable_get(ivar)
      return value if value

      if respond_to?(:read_state)
        value = instance_variable_set(ivar, read_state(sm))
      end

      value || sm.initial_state
    end
  end
end
