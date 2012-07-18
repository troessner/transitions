module Transitions
  module Extension
    extend ActiveSupport::Concern

    included do
      after_initialize :set_initial_state if self.respond_to?('after_initialize')
      validate :state_inclusion if self.respond_to?('validate')
    end

    module InstanceMethods
      # The optional options argument is passed to find when reloading so you may
      # do e.g. record.reload(:lock => true) to reload the same record with an
      # exclusive row lock. 
      def reload(options = nil)
        super.tap do
          if self.class.respond_to?('get_state_machine')
            sm = self.class.get_state_machine
            remove_instance_variable(sm.current_state_variable) if instance_variable_defined?(sm.current_state_variable)
          end
        end
      end

      protected

      def write_state(state)
        prev_state = current_state
        write_state_without_persistence(state)
        save! if self.respond_to?('save!')
      rescue ActiveRecord::RecordInvalid
        write_state_without_persistence(prev_state)
        raise
      end
      
      def write_state_without_persistence(state)
        sm = self.class.get_state_machine
        state_column = sm.state_column.to_s
        ivar = sm.current_state_variable
        instance_variable_set(ivar, state)
        self.send("#{state_column}=", state.to_s) if self.respond_to?("#{state_column}=")
      end

      def read_state
        state_column = self.class.get_state_machine.state_column.to_s
        mystate = self.send("#{state_column}") if self.respond_to?(state_column.to_sym)
        mystate && mystate.to_sym
      end

      def set_initial_state
        if self.respond_to?('state_machine_included?') && self.respond_to?('new_record?') && self.new_record?
          state_column = self.class.get_state_machine.state_column.to_s
          value = self.send("#{state_column}")
          self.send("#{state_column}=", self.class.get_state_machine.initial_state.to_s) if self.has_attribute?(state_column.to_sym) && value.nil?
        end
      end

      def state_inclusion
        if self.respond_to?('state_machine_included?')
          state_column = self.class.get_state_machine.state_column.to_s
          mystate = self.send("#{state_column}")
          unless self.class.get_state_machine.states.map{|s| s.name.to_s }.include?(mystate.to_s)
            self.errors.add(state_column.to_sym, :inclusion, :value => mystate)
          end
        end
      end
    end

    module ClassMethods
      # not really clean way, but this ensure backward compatibility
      def state_machine(options = {}, &block)
        include_state_machine unless self.respond_to?('state_machine_included?')
        # dangerous call ...
        state_machine(options, &block)
      end

      def include_state_machine
        class_eval do
          def state_machine_included?
            true
          end
          extend Transitions::Extension::DynamicClassMethods
        end
      end
    end

    module DynamicClassMethods
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
end
