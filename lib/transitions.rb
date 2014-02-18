require "transitions/event"
require "transitions/machine"
require "transitions/presenter"
require "transitions/state"
require "transitions/state_transition"
require "transitions/version"

module Transitions
  class InvalidTransition     < StandardError; end
  class InvalidMethodOverride < StandardError; end
  include Presenter

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

    def available_events
      @state_machine.events.keys.sort
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def update_current_state(new_state, persist = false)
    sm   = self.class.get_state_machine
    ivar = sm.current_state_variable
    if ::Transitions.active_record_descendant?(self.class)
      write_state(new_state) if persist
      write_state_without_persistence(new_state) # TODO This seems like a duplicate, `write_new` already calls `write_state_without_persistence`.
    end

    instance_variable_set(ivar, new_state)
  end

  def available_transitions
    self.class.get_state_machine.events_for(current_state)
  end

  def can_transition?(*events)
    events.all? do |event|
      self.class.get_state_machine.events_for(current_state).include?(event.to_sym)
    end
  end

  def cant_transition?(*events)
    !can_transition?(*events)
  end

  def current_state
    sm    = self.class.get_state_machine
    ivar  = sm.current_state_variable
    value = instance_variable_get(ivar)

    if ::Transitions.active_record_descendant?(self.class)
      value = read_state unless value.present?
    end

    value = sm.initial_state unless value.present?

    if ::Transitions.active_record_descendant?(self.class)
      instance_variable_set(ivar, value)
    end
    value
  end

  def self.active_record_descendant?(klazz)
    defined?(ActiveRecord::Base) && klazz < ActiveRecord::Base
  end
end
