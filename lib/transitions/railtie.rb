module Transitions
  class Railtie < ::Rails::Railtie #:nodoc:
    initializer 'transitions' do |app|
      Transitions::Hooks.init!
    end
  end
end
