module Transitions
  class Hooks
    def self.init!
      ActiveSupport.on_load(:active_record) do
        require 'transitions/active_record/transitions'
        ::ActiveRecord::Base.send :include, Transitions::ActiveRecordExtension
        #::ActiveRecord::Base.send :extend, Piktur::ActiveRecordExtension
      end
    end
  end
end
