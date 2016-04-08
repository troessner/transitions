module Transitions
  module Presenter
    def available_states
      get_state_machine.states.map(&:name)
    end

    def available_events
      get_state_machine.events.keys
    end
  end
end
