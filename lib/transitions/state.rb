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
  class State
    attr_reader :name, :options

    def initialize(name, options = {})
      @name = name
      if machine = options.delete(:machine)
        define_state_query_method(machine)
      end
      update(options)
    end

    def ==(state)
      if state.is_a? Symbol
        name == state
      else
        name == state.name
      end
    end

    def call_action(action, record)
      action = @options[action]
      case action
      when Symbol, String
        record.send(action)
      when Proc
        action.call(record)
      end
    end

    def display_name
      @display_name ||= name.to_s.gsub(/_/, ' ').capitalize
    end

    def for_select
      [display_name, name.to_s]
    end

    def update(options = {})
      @display_name = options.delete(:display) if options.key?(:display)
      @options = options
      self
    end

    private
    def define_state_query_method(machine)
      method_name, state_name = "#{@name}?", @name # Instance vars are out of scope when calling define_method below, so we use local variables.
      if method_already_defined_on_recipient?(machine, method_name)
        override_warning method_name
      else
        machine.klass.send :define_method, method_name do
          current_state.to_s == state_name.to_s
        end
      end
    end

    def method_already_defined_on_recipient?(machine, method_name)
      machine.klass.new.respond_to?(method_name)
    end

    def override_warning(method_name)
      warning = "Transitions: Can not define method #{method_name} because it is already defined, please rename either the existing method or the state."
      if Rails && Rails.logger
        Rails.logger.warn warning
      else
        puts warning
      end
    end
  end
end
