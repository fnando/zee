# frozen_string_literal: true

module Zee
  class Controller
    module Locals
      # The variables that will be exposed to templates.
      #
      # @return [Hash]
      #
      # @example
      #   locals[:name] = user.name
      private def locals
        @locals ||= {}
      end

      # Expose variables and methods to the template.
      #
      # @param helper_names [Array<Symbol>] The helper methods to expose. Notice
      #                                     that methods must be private.
      # @param vars [Hash] The variables to expose.
      #
      # @raise [UnsafeHelperError] If a helper method is not private.
      #
      # @example Expose a message to the template.
      #   expose message: "Hello, World!"
      #
      # @example Expose a helper method to the template.
      #   expose :say_hello
      private def expose(*helper_names, **vars)
        helper_names.each do |name|
          if self.class.public_method_defined?(name)
            raise UnsafeHelperError, "#{name.inspect} must be a private method"
          end

          ref = method(name)

          helpers.instance_eval do
            define_method(name) do |*args, **kwargs, &block|
              ref.call(*args, **kwargs, &block)
            end
          end
        end

        locals.merge!(vars)
      end
    end
  end
end
