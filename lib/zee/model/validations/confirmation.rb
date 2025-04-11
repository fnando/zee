# frozen_string_literal: true

module Zee
  class Model
    module Validations
      module Confirmation
        # @api private
        DEFAULT_MESSAGE = "doesn't match %{attribute}"

        # @api private
        def self.validate(model, attribute, options)
          confirmation_attribute = :"#{attribute}_confirmation"
          value = model[attribute]
          confirmation_value = model[confirmation_attribute]

          return if value == confirmation_value

          human_attr_name = Validations.human_attribute(model, attribute)
          translated_message = Validations.error_message(
            :confirmation,
            model,
            attribute,
            options: {attribute: human_attr_name}
          )

          message = [
            translated_message,
            (format(options[:message], attribute: human_attr_name) if options[:message]), # rubocop:disable Layout/LineLength
            format(DEFAULT_MESSAGE, attribute: human_attr_name)
          ].compact.first

          model.errors_with_details[confirmation_attribute].push(
            {error: :confirmation, message:, attribute:}
          )
        end

        # This method is used to validate the confirmation of attributes.
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
        def validates_confirmation_of(*names, **options)
          confirmation_attrs = names.map { :"#{_1}_confirmation" }
          attr_accessor(*confirmation_attrs)

          validations << Validator.new(Confirmation, names, options)
        end
      end
    end
  end
end
