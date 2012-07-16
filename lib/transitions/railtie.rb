module Transitions
  class Railtie < ::Rails::Railtie #:nodoc:
    initializer 'transitions' do |app|
      Transitions::Hooks.init!

      #Transitions.config.public_abs_path = Rails.root.join('public').to_s
    end
  end
end
