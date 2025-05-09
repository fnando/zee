# frozen_string_literal: true

module Zee
  module Listener
    # @api private
    class Listener
      def initialize(context, type, event, &block)
        @context = context
        @type = type
        @event = event
        @block = block
        @event_method = :"#{@type}_#{@event}"
      end

      def method_missing(method_name, *)
        return super unless respond_to_missing?(method_name, false)

        @block.call(*)
      end

      def to_s
        "<#{self.class} event: #{@event_method}>"
      end

      def respond_to_missing?(method_name, _include_private)
        method_name == @event_method
      end
    end
  end
end
