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
      include_scopes if @auto_scopes && ::Transitions.active_record_descendant?(klass)
      self
    end

    # TODO Refactor me please?
    def fire_event(event, record, persist, *args)
      state_index[record.current_state].call_action(:exit, record)
      begin
        if new_state = @events[event].fire(record, nil, *args)
          state_index[new_state].call_action(:enter, record)

          if record.respond_to?(:event_fired)
            record.send(:event_fired, record.current_state, new_state, event)
          end

          record.update_current_state(new_state, persist)
          @events[event].success.call(record) if @events[event].success
          return true
        else
          record.send(:event_failed, event) if record.respond_to?(:event_failed)
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

