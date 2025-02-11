# frozen_string_literal: true

module Zee
  class MiddlewareStack
    def initialize
      @store = []
    end

    # Add middleware to the end of the stack.
    # @param middleware [Class] The middleware class.
    # @param args [Array] The arguments to pass to the middleware.
    # @param block [Proc] The block to pass to the middleware.
    def use(middleware, *args, &block)
      @store << [middleware, args, block]
    end

    # Add a middleware to the beginning of the stack.
    # @param middleware [Class] The middleware class.
    # @param args [Array] The arguments to pass to the middleware.
    # @param block [Proc] The block to pass to the middleware.
    def unshift(middleware, *args, &block)
      @store.unshift([middleware, args, block])
    end

    # Convert the stack to an array.
    def to_a
      @store
    end

    # Clear the stack.
    def clear
      @store.clear
    end
  end
end
