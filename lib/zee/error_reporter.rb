# frozen_string_literal: true

module Zee
  class ErrorReporter
    def handlers
      @handlers ||= []
    end

    # Get the current error context.
    # This is a hash that will be passed to all error handlers.
    #
    # @return [Hash]
    #
    # @example
    #   Zee.error.context[:user_id] = 1
    def context
      RequestStore[:error_context] ||= {}
    end

    # Subscribe to error reports.
    # Handlers must respond to `call(error:, context:)`.
    #
    # @param handler [#call]
    #
    # @example
    #   class MyHandler
    #     def self.call(error:, context:)
    #       puts "Error: #{error.message}"
    #     end
    #   end
    #
    #   Zee.error.subscribe(MyHandler)
    #   Zee.error << MyHandler
    def subscribe(handler)
      handlers << handler
    end
    alias << subscribe

    # Unsubscribe from error reports.
    # @param handler [#call]
    #
    # @example
    #   Zee.error.unsubscribe(MyHandler)
    #   Zee.error >> MyHandler
    def unsubscribe(handler)
      handlers.delete(handler)
    end
    alias >> unsubscribe

    # Report an error.
    #
    # This method will call all the error handlers, passing the error and
    # context. If an error occurs in the handler, it will be raised _after_
    # all handlers have been called with the original error.
    #
    # The `context` hash will be merged with the context stored in the request
    # store's context. This allows you to set context globally, and then
    # override it in specific cases.
    #
    # Handlers must respond to `call(error:, context:)`.
    #
    # @param error [Exception]
    # @param context [Hash]
    #
    # @example
    #   Zee.error(StandardError.new)
    #   Zee.error(StandardError.new, context: {user_id: 1})
    def report(error, context: {})
      context = self.context.merge(context)
      handler_error = nil

      handlers.each do |handler|
        handler.call(error:, context:)
      rescue Exception => inner_error # rubocop:disable Lint/RescueException, Naming/RescuedExceptionsVariableName
        handler_error = inner_error
      end
    ensure
      raise handler_error if handler_error
    end
  end
end
