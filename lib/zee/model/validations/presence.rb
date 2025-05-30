# frozen_string_literal: true

module Zee
  class Model
    module Validations
      module Presence
        # @api private
        DEFAULT_MESSAGE = "can't be blank"

        using Core::Blank

        # @api private
        def self.validate(model, attribute, options)
          value = model[attribute]

          return unless value.blank?

          message = model.errors.build_error_message(
            :presence,
            attribute,
            default: options[:message] || DEFAULT_MESSAGE
          )

          model.errors.add(attribute, :presence, message:)
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
        #
        # @example
        #   validates_presence_of :email
        def validates_presence_of(*names, **options)
          validations << Validator.new(Presence, names, options)
        end
      end
    end
  end
end
