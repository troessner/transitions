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
  class InvalidTransition     < StandardError; end
  class InvalidMethodOverride < StandardError; end

  module ClassMethods
    def inherited(klass)
      super # Make sure we call other callbacks possibly defined upstream the ancestor chain.
      klass.state_machine = state_machine
    end

    # The only reason we need this method is for the inherited callback.
    def state_machine=(value)
      @state_machine = value.dup
    end

    def state_machine(options = {}, &block)
      @state_machine ||= Machine.new self
      block ? @state_machine.update(options, &block) : @state_machine
    end

    def get_state_machine; @state_machine; end

    def available_states
      @state_machine.states.map(&:name).sort_by {|x| x.to_s}
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  # TODO Do we need this method really? Also, it's not a beauty, refactor at least.
  def current_state(new_state = nil, persist = false)
    sm   = self.class.get_state_machine
    ivar = sm.current_state_variable
    if new_state
      if persist && respond_to?(:write_state)
        write_state(new_state)
      end

      if respond_to?(:write_state_without_persistence)
        write_state_without_persistence(new_state)
      end

      instance_variable_set(ivar, new_state)
    else
      instance_variable_set(ivar, nil) unless instance_variable_defined?(ivar)
      value = instance_variable_get(ivar)
      return value if value

      if respond_to?(:read_state)
        value = instance_variable_set(ivar, read_state)
      end

      value || sm.initial_state
    end
  end
end
