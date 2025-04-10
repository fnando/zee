# frozen_string_literal: true

module Zee
  class Model
    module Validations
      module Size
        DEFAULT_TOO_SHORT_MESSAGE =
          "is too short (minimum is %{count} characters)"

        DEFAULT_TOO_LONG_MESSAGE =
          "is too long (maximum is %{count} characters)"

        DEFAULT_WRONG_SIZE_MESSAGE =
          "is the wrong size (should be %{count} characters)"

        # @api private
        def self.validate(model, attribute, options)
          value = model[attribute]
          size = value.size

          range = options[:in]

          if range
            options[:minimum] = range.min if range.begin
            if range.end
              options[:maximum] =
                (range.exclude_end? ? range.end - 1 : range.end)
            end
          end

          validate_minimum_size(model, attribute, value, size, options)
          validate_maximum_size(model, attribute, value, size, options)
          validate_exact_size(model, attribute, value, size, options)
        end

        def self.validate_exact_size(model, attribute, _value, size, options)
          return unless options[:is]
          return if size == options[:is]

          message_options = {count: options[:is]}
          message = Validations.error_message(:wrong_size, model, attribute) ||
                    options[:wrong_size] ||
                    options[:message] ||
                    DEFAULT_WRONG_SIZE_MESSAGE
          message = format(message, message_options)
          model.errors_with_details[attribute].push(
            {
              error: :size,
              message:,
              size:,
              is: options[:is]
            }
          )
        end

        def self.validate_minimum_size(model, attribute, _value, size, options)
          return unless options[:minimum]
          return if size >= options[:minimum]

          message_options = {count: options[:minimum]}
          message = Validations.error_message(:too_short, model, attribute) ||
                    options[:too_short] ||
                    options[:message] ||
                    DEFAULT_TOO_SHORT_MESSAGE
          message = format(message, message_options)
          model.errors_with_details[attribute].push(
            {
              error: :size,
              message:,
              size:,
              minimum: options[:minimum]
            }
          )
        end

        def self.validate_maximum_size(model, attribute, _value, size, options)
          return unless options[:maximum]
          return if size <= options[:maximum]

          message_options = {count: options[:maximum]}
          message = Validations.error_message(:too_long, model, attribute) ||
                    options[:too_long] ||
                    options[:message] ||
                    DEFAULT_TOO_LONG_MESSAGE
          message = format(message, message_options)
          model.errors_with_details[attribute].push(
            {
              error: :size,
              message:,
              size:,
              maximum: options[:maximum]
            }
          )
        end

        # This method is used to validate the size of attributes.
        # @param names [Symbol] The names of the attributes to validate.
        # @param options [Hash] The options for the validation.
        # @option options [String] :message The error message to use if the
        #                                   validation fails.
        # @option options [Symbol] :if A condition to check before validating.
        # @option options [Symbol] :unless A condition to check before
        #                                  validating.
        # @option options [Symbol] :allow_nil Whether to allow nil values.
        # @option options [Symbol] :allow_blank Whether to allow blank values.
        # @option options [Numeric] :is The exact size of the attribute.
        # @option options [Numeric] :minimum The minimum size of the attribute.
        # @option options [Numeric] :maximum The maximum size of the attribute.
        # @option options [Numeric] :in The range of valid sizes for the
        #                               attribute.
        def validates_size_of(*names, **options)
          validations << Validator.new(Size, names, options)
        end
        alias validates_length_of validates_size_of
      end
    end
  end
end
