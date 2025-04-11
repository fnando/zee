# frozen_string_literal: true

module Zee
  class Model
    module Validations
      module Inclusion
        # @api private
        DEFAULT_MESSAGE = "is not a valid %{attribute}"

        # @api private
        def self.validate(model, attribute, options)
          value = model[attribute]

          if options[:in].respond_to?(:cover?)
            return if options[:in].cover?(value)
          elsif options[:in].include?(value)
            return
          end

          message_options = {
            attribute: Validations.human_attribute(model, attribute),
            value:
          }

          message =
            Validations.error_message(
              :inclusion,
              model,
              attribute,
              options: message_options
            ) ||
            options[:message] ||
            DEFAULT_MESSAGE

          model.errors_with_details[attribute].push(
            {
              error: :inclusion,
              value:,
              message: format(message, message_options)
            }
          )
        end

        # This method is used to validate the inclusion of attributes within a
        # list of values.
        #
        # @param names [Symbol] The names of the attributes to validate.
        # @param options [Hash] The options for the validation.
        # @option options [String] :message The error message to use if the
        #                                   validation fails.
        # @option options [Symbol] :if A condition to check before validating.
        # @option options [Symbol] :unless A condition to check before
        #                                  validating.
        # @option options [Boolean] :allow_nil Whether to allow nil values.
        # @option options [Boolean] :allow_blank Whether to allow blank values.
        # @option options [Array] :in The list of allowed values.
        def validates_inclusion_of(*names, **options)
          validations << Validator.new(Inclusion, names, options)
        end
      end
    end
  end
end
