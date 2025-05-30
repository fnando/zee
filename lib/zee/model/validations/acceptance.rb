# frozen_string_literal: true

module Zee
  class Model
    module Validations
      module Acceptance
        # @api private
        DEFAULT_MESSAGE = "must be accepted"

        # @api private
        DEFAULT_ACCEPT = ["1", true, "true"].freeze

        # @api private
        def self.validate(model, attribute, options)
          value = model[attribute]

          return if options[:accept].include?(value)

          message = model.errors.build_error_message(
            :acceptance,
            attribute,
            default: options[:message] || DEFAULT_MESSAGE
          )

          model.errors.add(attribute, :acceptance, message:)
        end

        # This method is used to validate the acceptance of attributes.
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
        # @option options [Array] :accept The accepted values. Defaults
        #                                 to `["1", "true", true]`.
        #
        # @example
        #   validates_acceptance_of :terms_of_service
        #   validates_acceptance_of :eula, message: "must be abided"
        def validates_acceptance_of(*names, **options)
          options = {accept: DEFAULT_ACCEPT}.merge(options)
          validations << Validator.new(Acceptance, names, options)
        end
      end
    end
  end
end
