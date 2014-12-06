module Transitions
  class StateTransition
    attr_reader :from, :to, :options

    def initialize(opts)
      @from, @to, @guard, @on_transition = opts[:from], opts[:to], opts[:guard], opts[:on_transition]
      @options = opts
    end

    def executable?(obj, *args)
      [@guard].flatten.all? { |g| perform_guard(obj, g, *args) }
    end

    def execute(obj, *args)
      case @on_transition
      when Symbol, String
        obj.send(@on_transition, *args)
      when Proc
        @on_transition.call(obj, *args)
      when Array
        @on_transition.each do |callback|
          # Yes, we're passing always the same parameters for each callback in here.
          # We should probably drop args altogether in case we get an array.
          obj.send(callback, *args)
        end
      else
        # TODO We probably should check for this in the constructor and not that late.
        fail ArgumentError, "You can only pass a Symbol, a String, a Proc or an Array to 'on_transition' - got #{@on_transition.class}." unless @on_transition.nil?
      end
    end

    def ==(obj)
      @from == obj.from && @to == obj.to
    end

    def from?(value)
      @from == value
    end

    private

    def perform_guard(obj, guard, *args)
      if guard.respond_to?(:call)
        guard.call(obj, *args)
      elsif guard.is_a?(Symbol) || guard.is_a?(String)
        obj.send(guard, *args)
      else
        true
      end
    end
  end
end
