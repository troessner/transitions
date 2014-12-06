module Transitions
  class Machine
    attr_writer :initial_state
    attr_accessor :states, :events, :state_index
    attr_reader :klass, :auto_scopes

    def initialize(klass, options = {}, &block)
      @klass, @states, @state_index, @events = klass, [], {}, {}
      update(options, &block)
    end

    def initial_state
      @initial_state ||= (states.first ? states.first.name : nil)
    end

    def update(options = {}, &block)
      @initial_state = options[:initial] if options.key?(:initial)
      @auto_scopes = options[:auto_scopes]
      instance_eval(&block) if block
      include_scopes if @auto_scopes && ::Transitions.active_model_descendant?(klass)
      self
    end

    # TODO There is still way to much parameter passing around going on down below.
    def fire_event(event, record, persist, *args)
      handle_state_exit_callback record
      if new_state = transition_to_new_state(record, event, *args)
        handle_state_enter_callback record, new_state
        handle_event_fired_callback record, new_state, event
        record.update_current_state(new_state, persist)
        handle_event_success_callback record, event
        return true
      else
        handle_event_failed_callback record, event
        return false
      end
    rescue => e
      if record.respond_to?(:event_failed)
        record.send(:event_failed, event)
        return false
      else
        raise e
      end
    end

    def events_for(state)
      events = @events.values.select { |event| event.transitions_from_state?(state) }
      events.map! { |event| event.name }
    end

    def current_state_variable
      # TODO Refactor me away.
      :@current_state
    end

  private

    def handle_state_exit_callback(record)
      state_index[record.current_state].call_action(:exit, record)
    end

    def transition_to_new_state(record, event, *args)
      @events[event].fire(record, nil, *args)
    end

    def handle_state_enter_callback(record, new_state)
      state_index[new_state].call_action(:enter, record)
    end

    def handle_event_fired_callback(record, new_state, event)
      if record.respond_to?(:event_fired, true)
        record.send(:event_fired, record.current_state, new_state, event)
      end
    end

    def handle_event_success_callback(record, event)
      @events[event].success.call(record) if @events[event].success
    end

    def handle_event_failed_callback(record, event)
      if record.respond_to?(:event_failed, true)
        record.send(:event_failed, event)
      end
    end

    def state(name, options = {})
      unless @state_index.key? name # Just ignore duplicates
        state = State.new(name, :machine => self)
        state.update options
        @state_index[name] = state
        @states << state
      end
    end

    def event(name, options = {}, &block)
      (@events[name] ||= Event.new(self, name)).update(options, &block)
    end

    def include_scopes
      @states.each do |state|
        state_name = state.name.to_s
        if @klass.respond_to?(state_name)
          raise InvalidMethodOverride, "Transitions: Can not define scope `#{state_name}` because there is already an equally named method defined - either rename the existing method or the state."
        end
        @klass.scope state_name, -> { @klass.where(@klass.state_machine.attribute_name => state_name) }
      end
    end
  end
end

