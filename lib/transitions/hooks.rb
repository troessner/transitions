module Transitions
  class Hooks
    def self.init!
      ActiveSupport.on_load(:active_record) do
        require 'transitions/extension/transitions'
        ::ActiveRecord::Base.send :include, Transitions::Extension
      end
    end
  end
end
