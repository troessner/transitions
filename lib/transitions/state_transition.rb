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
  class StateTransition
    attr_reader :from, :to, :options

    def initialize(opts)
      @from, @to, @guard, @on_transition = opts[:from], opts[:to], (opts[:guard] || opts[:if]), (opts[:on_transition] || opts[:do])
      @options = opts
    end

    def perform(obj)
      case @guard
      when Symbol, String
        obj.send(@guard)
      when Proc
        if @guard.lambda?
          @guard.call(obj)
        else
          obj.instance_eval(&@guard)
        end
      else
        true
      end
    end

    def execute(obj, *args)
      case @on_transition
      when Symbol, String
        obj.send(@on_transition, *args)
      when Proc
        if @on_transition.lambda?
          @on_transition.call(obj, *args)
        else
          obj.instance_exec(*args, &@on_transition)
        end
      when Array
        @on_transition.each do |callback|
          # Yes, we're passing always the same parameters for each callback in here.
          # We should probably drop args altogether in case we get an array.
          obj.send(callback, *args)
        end
      else
        # TODO We probably should check for this in the constructor and not that late.
        raise ArgumentError, "You can only pass a Symbol, a String, a Proc or an Array to 'on_transition' - got #{@on_transition.class}." unless @on_transition.nil?
      end
    end

    def ==(obj)
      @from == obj.from && @to == obj.to
    end

    def from?(value)
      @from == value
    end
  end
end
