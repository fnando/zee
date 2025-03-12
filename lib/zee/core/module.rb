# frozen_string_literal: true

module Zee
  module Core
    module Module
      refine ::Module do
        # Internal attribute readers are methods that have a public name, but
        # are meant to be used internally by the module. To avoid conflicts,
        # the instance variable is prefixed with an underscore.
        #
        # @example
        #   ```ruby
        #   class MyClass
        #     internal_attr_reader :controller
        #
        #     def initialize(controller)
        #       @_controller = controller
        #     end
        #   end
        #   ```
        def internal_attr_reader(*names)
          names.each do |name|
            define_method(name) do
              instance_variable_get(:"@_#{name}")
            end
          end
        end
      end
    end
  end
end
