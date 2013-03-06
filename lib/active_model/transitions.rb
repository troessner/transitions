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
      class ::Transitions::Machine
        unless instance_methods.include?(:new_transitions_initialize) || instance_methods.include?(:new_transitions_update)
          attr_reader :attribute_name
          alias :old_transitions_initialize :initialize
          alias :old_transitions_update :update

          def new_transitions_initialize(*args, &block)
            @attribute_name = :state
            old_transitions_initialize(*args, &block)
          end

          def new_transitions_update(options = {}, &block)
            @attribute_name = options[:attribute_name] if options.key?(:attribute_name)
            old_transitions_update(options, &block)
          end

          alias :initialize :new_transitions_initialize
          alias :update :new_transitions_update
        end
      end
      include ::Transitions
      after_initialize :set_initial_state
      validate :state_presence
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

    def transitions_state_column_name
      self.class.state_machine.attribute_name
    end

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
      self[transitions_state_column_name] = state.to_s
    end

    def read_state
      self[transitions_state_column_name] && self[transitions_state_column_name].to_sym
    end

    def set_initial_state
      self[transitions_state_column_name] ||= self.class.get_state_machine.initial_state.to_s if self.respond_to?(transitions_state_column_name)
    end

    def state_presence
      unless self[transitions_state_column_name].present?
        self.errors.add(transitions_state_column_name, :presence)
      end
    end

    def state_inclusion
      unless self.class.get_state_machine.states.map{|s| s.name.to_s }.include?(self[transitions_state_column_name].to_s)
        self.errors.add(transitions_state_column_name, :inclusion, :value => self[transitions_state_column_name])
      end
    end
  end
end