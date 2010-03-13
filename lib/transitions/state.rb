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
        machine.klass.define_state_query_method(name)
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
  end
end
