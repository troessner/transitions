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
  class Event
    
    attr_reader :name, :success, :timestamp

    def initialize(machine, name, options = {}, &block)
      @machine, @name, @transitions = machine, name, []
      if machine
        machine.klass.send(:define_method, "#{name}!") do |*args|
          machine.fire_event(name, self, true, *args)
        end

        machine.klass.send(:define_method, name.to_s) do |*args|
          machine.fire_event(name, self, false, *args)
        end
      end
      update(options, &block)
    end

    
    def fire(obj, to_state = nil, *args)
      transitions = @transitions.select { |t| t.from == obj.current_state(@machine ? @machine.name : nil) }
      raise InvalidTransition if transitions.size == 0

      next_state = nil
      transitions.each do |transition|
        next if to_state && !Array(transition.to).include?(to_state)
        if transition.perform(obj)
          next_state = to_state || Array(transition.to).first
          transition.execute(obj, *args)
          break
        end
      end
      
      # Update timestamps on obj if a timestamp has been specified
      update_event_timestamp(obj, next_state) if timestamp?

      next_state
    end
    
    # update the timestamp attribute on obj
    def update_event_timestamp(obj, next_state)
      obj.send "#{timestamp_attribute_name(obj, next_state)}=", Time.now
    end
    
    # Has timestamp been specified?
    def timestamp?
      !!@timestamp
    end

    def transitions_from_state?(state)
      @transitions.any? { |t| t.from? state }
    end

    def ==(event)
      if event.is_a? Symbol
        name == event
      else
        name == event.name
      end
    end

    def update(options = {}, &block)
      @success = options[:success] if options.key?(:success)
      @timestamp = options[:timestamp]
      instance_eval(&block) if block
      self
    end

    private
    
    # Returns the name of the timestamp attribute for this event
    def timestamp_attribute_name(obj, next_state)
      if @timestamp == true
        default_timestamp_name(obj, next_state)
      else
        @timestamp
      end
    end
    
    # If @timestamp is true, try a default timestamp name
    def default_timestamp_name(obj, next_state)
      at_name = "%s_at" % next_state
      on_name = "%s_on" % next_state
      case
      when obj.respond_to?(at_name) then at_name
      when obj.respond_to?(on_name) then on_name
      else
        raise NoMethodError, "Couldn't find a suitable timestamp field for event: #{@name}. 
          Please define #{at_name} or #{on_name} in #{obj.class}"
      end
    end

    def transitions(trans_opts)
      Array(trans_opts[:from]).each do |s|
        @transitions << StateTransition.new(trans_opts.merge({:from => s.to_sym}))
      end
    end
  end
end
