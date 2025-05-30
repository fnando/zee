# frozen_string_literal: true

module Zee
  class Model
    module Validations
      module Exclusion
        # @api private
        DEFAULT_MESSAGE = "is not a valid %{attribute}"

        # @api private
        def self.validate(model, attribute, options)
          value = model[attribute]

          if options[:in].respond_to?(:cover?)
            return unless options[:in].cover?(value)
          elsif !options[:in].include?(value)
            return
          end

          message_options = {
            attribute: model.errors.human_attribute_name(attribute),
            value:
          }

          message =
            model.errors.build_error_message(
              :exclusion,
              attribute,
              options: message_options,
              default: options[:message] || DEFAULT_MESSAGE
            )

          model.errors.add(
            attribute,
            :exclusion,
            value:,
            message: format(message, message_options)
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
        #
        # @example
        #   validates_exclusion_of :username, in: %w[admin superuser]
        #   validates_exclusion_of :age, in: 30..60
        #   validates_exclusion_of :format, in: %w[mov avi],
        #                           message: "extension %{value} is not allowed"
        def validates_exclusion_of(*names, **options)
          validations << Validator.new(Exclusion, names, options)
        end
      end
    end
  end
end
