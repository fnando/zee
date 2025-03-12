# frozen_string_literal: true

module Zee
  class Controller
    module Locals
      def self.included(controller)
        controller.extend(ClassMethods)
      end

      module ClassMethods
        # Expose helper methods to templates.
        # With this method, you can expose helper methods to all actions.
        #
        # @see Locals#expose
        #
        # @example Expose a helper method to all actions.
        #   class ApplicationController < Zee::Controller
        #     expose :current_user, :user_logged_in?
        #
        #     private def current_user
        #       @current_user ||=
        #         Models::User.find(session[:user_id]) if session[:user_id]
        #     end
        #
        #     private def user_logged_in?
        #       current_user != nil
        #     end
        #   end
        def expose(*, **)
          before_action { expose(*, **) }
        end
      end

      # The variables that will be exposed to templates.
      #
      # @return [Hash]
      #
      # @example
      #   locals[:name] = user.name
      private def locals
        @_locals ||= {}
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
          file, line = ref.source_location

          helpers.instance_eval <<~RUBY, file, line + 1 # rubocop:disable Style/EvalWithLocation
            def #{name}(*, **)                   # def hello(*, **)
              controller.send(:"#{name}", *, **) #  controller.send(:hello, *, **)
            end                                  # end
          RUBY
        end

        locals.merge!(vars)
      end
    end
  end
end
