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
    attr_reader :klass, :name

    def initialize(klass, name, options = {}, &block)
      @klass, @name, @states, @state_index, @events = klass, name, [], {}, {}
      update(options, &block)
    end

    def initial_state
      @initial_state ||= (states.first ? states.first.name : nil)
    end

    def update(options = {}, &block)
      @initial_state = options[:initial] if options.key?(:initial)
      instance_eval(&block) if block
      self
    end

    def fire_event(event, record, persist, *args)
      state_index[record.current_state(@name)].call_action(:exit, record)
      if new_state = @events[event].fire(record, nil, *args)
        state_index[new_state].call_action(:enter, record)

        if record.respond_to?(event_fired_callback)
          record.send(event_fired_callback, record.current_state, new_state)
        end

        record.current_state(@name, new_state, persist)
        record.send(@events[event].success) if @events[event].success
        true
      else
        if record.respond_to?(event_failed_callback)
          record.send(event_failed_callback, event)
        end

        false
      end
    end

    def states_for_select
      states.map { |st| [st.display_name, st.name.to_s] }
    end

    def events_for(state)
      events = @events.values.select { |event| event.transitions_from_state?(state) }
      events.map! { |event| event.name }
    end

    def current_state_variable
      "@#{@name}_current_state"
    end

    private

    def state(name, options = {})
      @states << (state_index[name] ||= State.new(name, :machine => self)).update(options)
    end

    def event(name, options = {}, &block)
      (@events[name] ||= Event.new(self, name)).update(options, &block)
    end

    def event_fired_callback
      @event_fired_callback ||= (@name == :default ? '' : "#{@name}_") + 'event_fired'
    end

    def event_failed_callback
      @event_failed_callback ||= (@name == :default ? '' : "#{@name}_") + 'event_failed'
    end
  end
end

