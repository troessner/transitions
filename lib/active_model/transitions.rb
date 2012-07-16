# for backward compatibility
module ActiveModel
  module Transitions
    def self.included(base)
      puts "BACKWARD COMPATIBILITY WARNING ... Please upgrade your code for Transition gem"
    end
  end
end
