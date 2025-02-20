# frozen_string_literal: true

module Zee
  class FormBuilder
    class Label < Base
      # The label's text.
      # @return [String]
      attr_reader :text

      # The label's options.
      # @return [Hash{Symbol => Object}]
      # @option options [String] :class the label's class.
      attr_reader :options

      def initialize(text:, **options)
        super()
        @text = text
        @options = options
      end

      def view_template
        label(class: class_names("field--label", options[:class]), **options) do
          text
        end
      end
    end
  end
end
