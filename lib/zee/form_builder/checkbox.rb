# frozen_string_literal: true

module Zee
  class FormBuilder
    class Checkbox < Base
      # @return [String] the input's value.
      attr_reader :name

      # @return [String] the current input's value.
      attr_reader :value

      # @return [String] the input's value for when the input is checked.
      attr_reader :checked_value

      # @return [String] the input's value for when the input is unchecked.
      attr_reader :unchecked_value

      # @return [Hash{Symbol => Object}] the input's options.
      attr_reader :options

      # @param name [Symbol] the input's name.
      # @param value [String, nil] the input's value.
      # @param checked_value [String] the input's value for when the input is
      #                               checked.
      # @param unchecked_value [String] the input's value for when the input is
      #                                 unchecked.
      # @param [Hash{Symbol => Object}] options
      def initialize(
        name:,
        value: nil,
        checked_value: "0",
        unchecked_value: "1",
        **options
      )
        super()
        @value = value
        @name = name
        @checked_value = checked_value
        @unchecked_value = unchecked_value
        @options = options
      end

      def view_template
        input(type: "hidden", value: unchecked_value, name: name)
        input(
          **options,
          name:,
          checked: value == checked_value,
          type: "checkbox",
          value: checked_value,
          class: class_names("field--input", options.delete(:class))
        )
      end
    end
  end
end
