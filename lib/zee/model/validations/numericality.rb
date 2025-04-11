# frozen_string_literal: true

module Zee
  class Model
    module Validations
      module Numericality
        # @api private
        DEFAULT_ONLY_INTEGER_MESSAGE = "is not an integer"

        # @api private
        DEFAULT_GT_MESSAGE = "is not greater than %{value}"

        # @api private
        DEFAULT_GTE_MESSAGE = "is not greater than or equal to %{value}"

        # @api private
        DEFAULT_EQ_MESSAGE = "is not equal to %{value}"

        # @api private
        DEFAULT_LT_MESSAGE = "is not less than %{value}"

        # @api private
        DEFAULT_LTE_MESSAGE = "is not less than or equal to %{value}"

        # @api private
        DEFAULT_OEQ_MESSAGE = "is different than %{value}"

        # @api private
        DEFAULT_ODD_MESSAGE = "is not an odd number"

        # @api private
        DEFAULT_EVEN_MESSAGE = "is not an even number"

        # @api private
        CHECKS = {
          greater_than: [:>, DEFAULT_GT_MESSAGE],
          greater_than_or_equal_to: [:>=, DEFAULT_GTE_MESSAGE],
          equal_to: [:==, DEFAULT_EQ_MESSAGE],
          less_than: [:<, DEFAULT_LT_MESSAGE],
          less_than_or_equal_to: [:<=, DEFAULT_LTE_MESSAGE],
          other_than: [:!=, DEFAULT_OEQ_MESSAGE]
        }.freeze

        # @api private
        def self.validate(model, attribute, options)
          value = model[attribute]
          validate_integer(model, attribute, value, options)
          validate_operators(model, attribute, value, options)
          validate_odd(model, attribute, value, options)
          validate_even(model, attribute, value, options)
        end

        # @api private
        def self.validate_operators(model, attribute, value, options)
          options.each do |check, expected|
            next unless CHECKS[check]

            operator, message = CHECKS[check]

            next if value.send(operator, expected)

            message =
              model.errors.error_message_for(check, attribute) || message

            message = format(message, {value: expected})

            model.errors.add(
              attribute,
              :numericality,
              value:,
              message:,
              check:,
              expected:
            )
          end
        end

        # @api private
        def self.validate_integer(model, attribute, value, options)
          return unless options[:only_integer]
          return if value.nil? || value.is_a?(Integer)

          message =
            model.errors.error_message_for(:not_an_integer, attribute) ||
            DEFAULT_ONLY_INTEGER_MESSAGE

          model.errors.add(
            attribute,
            :numericality,
            value:,
            message:,
            check: :integer
          )
        end

        # @api private
        def self.validate_odd(model, attribute, value, options)
          return unless options[:odd]
          return if value.odd?

          message =
            model.errors.error_message_for(:odd, attribute) ||
            DEFAULT_ODD_MESSAGE

          model.errors.add(
            attribute,
            :numericality,
            value:,
            message:,
            check: :odd
          )
        end

        # @api private
        def self.validate_even(model, attribute, value, options)
          return unless options[:even]
          return if value.even?

          message =
            model.errors.error_message_for(:even, attribute) ||
            DEFAULT_EVEN_MESSAGE

          model.errors.add(
            attribute,
            :numericality,
            value:,
            message:,
            check: :even
          )
        end

        # This method is used to validate the presence of attributes.
        # @param names [Symbol] The names of the attributes to validate.
        # @param options [Hash] The options for the validation.
        # @option options [String] :message The error message to use if the
        #                                   validation fails.
        # @option options [Symbol] :if A condition to check before validating.
        # @option options [Symbol] :unless A condition to check before
        #                                  validating.
        # @option options [Boolean] :allow_nil Whether to allow nil values.
        # @option options [Boolean] :allow_blank Whether to allow blank values.
        # @option options [Boolean] :only_integer Whether to only allow integer
        #                                         values.
        # @option options [Numeric] :greater_than The minimum value.
        # @option options [Numeric] :greater_than_or_equal_to The minimum value.
        # @option options [Numeric] :equal_to The exact value.
        # @option options [Numeric] :less_than The maximum value.
        # @option options [Numeric] :less_than_or_equal_to The maximum value.
        # @option options [Numeric] :other_than The value that is not allowed.
        # @option options [Boolean] :odd Whether to allow odd values.
        # @option options [Boolean] :even Whether to allow even values.
        def validates_numericality_of(*names, **options)
          validations << Validator.new(Numericality, names, options)
        end
      end
    end
  end
end
