require 'transitions/active_model/transitions'

#module ActiveRecord
#  Transitions = ActiveModel::Transitions
#end

module Transitions
  module ActiveRecordExtension
    extend ActiveSupport::Concern

#    included do
#      #include ::Transitions
#      after_initialize :set_initial_state
#      #validates_presence_of :state
#      #validate :state_inclusion
#    end

    module InstanceMethods
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
        state_column = self.class.get_state_machine.state_column.to_s
        value = self.send("#{state_column}")
        #self.send("#{state_column}=", self.class.get_state_machine.initial_state.to_s) if self.has_attribute?(state_column.to_sym) && value.nil?
        self.send("#{state_column}=", self.class.get_state_machine.initial_state.to_s) #if self.has_attribute?(state_column.to_sym) && value.nil?
      end

      def state_inclusion
        state_column = self.class.get_state_machine.state_column.to_s
        mystate = self.send("#{state_column}")
        unless self.class.get_state_machine.states.map{|s| s.name.to_s }.include?(mystate.to_s)
          self.errors.add(state_column.to_sym, :inclusion, :value => mystate)
        end
      end
    end

    module ClassMethods
      #def inherited(klass)
      #  puts "CLASS METHODS INHERITED"
      #end

      # not really clean way, but this ensure backward compatibility
      def state_machine(options = {}, &block)
        # unless should be useless
        include_state_machine unless self.respond_to?('state_machine_included?')
        #puts "running include_state_machine dynamicly"
        # dangerous call ...
        state_machine(options, &block)
      end

      def include_state_machine
        class_eval do
          def state_machine_included?
            true
          end
          extend Transitions::ActiveRecordExtension::DynamicClassMethods
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

#    def self.included(base)
#puts "INCLUDED2"
#puts "transitions / active_record included..."
#puts "base #{base} extend ClassMethods"
#      base.extend(ClassMethods)
#    end

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
