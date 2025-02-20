# frozen_string_literal: true

module Zee
  class FormBuilder
    class Input < Base
      # @return [Symbol] the input's type.
      attr_reader :type

      # @return [String] the input's value.
      attr_reader :name

      # @return [String] the input's value.
      attr_reader :value

      # @return [Hash{Symbol => Object}] the input's options.
      attr_reader :options

      # @param type [Symbol] the input's type.
      # @param name [Symbol] the input's name.
      # @param value [String] the input's value.
      # @param [Hash{Symbol => Object}] options
      def initialize(name:, value: nil, type: :text, **options)
        super()
        @type = type
        @name = name
        @value = value
        @options = options
      end

      def view_template
        input(
          **process_attributes(options),
          type:,
          name:,
          value:,
          class: class_names(
            "field--input",
            options.delete(:class)
          )
        )
      end
    end
  end
end
