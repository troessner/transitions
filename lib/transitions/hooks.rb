module Transitions
  class Hooks
    def self.init!
      ActiveSupport.on_load(:active_record) do
        require 'transitions/active_record/transitions'
        ::ActiveRecord::Base.send :include, Transitions::ActiveRecordExtension
      end
    end
  end
end
