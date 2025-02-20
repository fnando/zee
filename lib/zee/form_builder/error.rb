# frozen_string_literal: true

module Zee
  class FormBuilder
    class Error < Base
      # The label's text.
      # @return [String]
      attr_reader :text

      # The error's options.
      # @return [Hash{Symbol => Object}]
      # @option options [String] :class the error's class.
      attr_reader :options

      def initialize(text:, **options)
        super()
        @text = text
        @options = options
      end

      def view_template
        span(class: class_names("field--error", options[:class]), **options) do
          text
        end
      end
    end
  end
end
