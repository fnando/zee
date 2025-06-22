# frozen_string_literal: true

module Zee
  class MiddlewareStack
    # @api private
    # The application instance.
    # @return [Zee::App]
    attr_reader :app

    # Initialize the middleware stack.
    # @param app [Zee::App] The application instance.
    # @return [Zee::MiddlewareStack]
    def initialize(app = nil)
      @app = app
      @store = []
    end

    # Add middleware to the end of the stack.
    # @param middleware [Class] The middleware class.
    # @param args [Array] The arguments to pass to the middleware.
    # @param kwargs [Hash] The keyword arguments to pass to the middleware.
    # @param block [Proc] The block to pass to the middleware.
    def use(middleware, *args, **kwargs, &block)
      @store << [middleware, args, kwargs, block]
    end

    # Add a middleware to the beginning of the stack.
    # @param middleware [Class] The middleware class.
    # @param args [Array] The arguments to pass to the middleware.
    # @param kwargs [Hash] The keyword arguments to pass to the middleware.
    # @param block [Proc] The block to pass to the middleware.
    def unshift(middleware, *args, **kwargs, &block)
      @store.unshift([middleware, args, kwargs, block])
    end

    # Convert the stack to an array.
    def to_a
      @store
    end

    # Clear the stack.
    def clear
      @store.clear
    end

    # Remove a middleware from the stack.
    # @param middleware [Class] The middleware to remove.
    def delete(middleware)
      @store.delete_if {|(m, _)| m == middleware }
    end
  end
end
