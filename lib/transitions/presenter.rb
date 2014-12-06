module Transitions
  module Presenter
    def available_states
      @state_machine.states.map(&:name).sort_by(&:to_s)
    end

    def available_events
      @state_machine.events.keys.sort
    end

    def available_transitions
      @state_machine.events_for(current_state)
    end
  end
end
