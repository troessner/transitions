module Transitions
  module Presenter
    def available_states
      get_state_machine.states.map(&:name).sort_by(&:to_s)
    end

    def available_events
      get_state_machine.events.keys.sort
    end
  end
end
