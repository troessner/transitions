module ActiveModel
  module Transitions
    extend ActiveSupport::Concern

    included do
      class ::Transitions::Machine
        unless method_defined?(:new_transitions_initialize) || method_defined?(:new_transitions_update)
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
    def reload(*)
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
      # In case we use a query with a custom select that excludes our state attribute name we need to skip the initialization below.
      if self.has_attribute?(transitions_state_column_name) && state_not_set?
        self[transitions_state_column_name] = self.class.get_state_machine.initial_state.to_s
        self.class.get_state_machine.state_index[self[transitions_state_column_name].to_sym].call_action(:enter, self)
      end
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

    def state_not_set?
      self[transitions_state_column_name].nil?
    end
  end
end
