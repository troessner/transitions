module Transitions
  class StateTransition
    attr_reader :from, :to, :guard, :on_transition
    # TODO: `from` and `to` should be private as well
    private :guard, :on_transition

    def initialize(opts)
      @from = opts[:from]
      @to = opts[:to]
      @guard = opts[:guard]
      @on_transition = opts[:on_transition]
      @options = opts
    end

    #
    # @param obj [Any] - the subject
    # @param args [Array<Symbol>] - any arguments passed into the transition method
    #   E.g. something like
    #     car.drive!(:fast, :now)
    #   with `car` being the subject and `drive` the transition method would result
    #   in `args` looking like this:
    #     [:fast, :now]
    #
    # @return [Bool]
    #
    def executable?(obj, *args, **kwargs)
      [@guard].flatten.all? { |g| perform_guard(obj, g, *args, **kwargs) }
    end

    #
    # @param obj [Any] - the subject
    # @param args [Array<Symbol>] - any arguments passed into the transition method
    #   E.g. something like
    #     car.drive!(:fast, :now)
    #   with `car` being the subject and `drive` the transition method would result
    #   in `args` looking like this:
    #     [:fast, :now]
    #
    # @return [void]
    #
    # rubocop:disable Metrics/MethodLength
    #
    def execute(obj, *args, **kwargs)
      case @on_transition
      when Symbol, String
        obj.send(@on_transition, *args, **kwargs)
      when Proc
        @on_transition.call(obj, *args, **kwargs)
      when Array
        @on_transition.each do |callback|
          # Yes, we're passing always the same parameters for each callback in here.
          # We should probably drop args altogether in case we get an array.
          obj.send(callback, *args, **kwargs)
        end
      else
        # TODO: We probably should check for this in the constructor and not that late.
        fail ArgumentError,
             "You can only pass a Symbol, a String, a Proc or an Array to 'on_transition'"\
             " - got #{@on_transition.class}." unless @on_transition.nil?
      end
    end

    def ==(other)
      @from == other.from && @to == other.to
    end

    def from?(value)
      @from == value
    end

    private

    def perform_guard(obj, guard, *args, **kwargs)
      if guard.respond_to?(:call)
        guard.call(obj, *args, **kwargs)
      elsif guard.is_a?(Symbol) || guard.is_a?(String)
        obj.send(guard, *args, **kwargs)
      else
        true
      end
    end
  end
end
