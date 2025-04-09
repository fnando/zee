# frozen_string_literal: true

module Zee
  class Model
    module Validations
      module Presence
        DEFAULT_MESSAGE = "can't be blank"

        using Core::Blank

        def self.validate(model, attribute, options)
          value = model[attribute]

          return unless value.blank?

          message = Validations.error_message(:presence, model, attribute) ||
                    options[:message] ||
                    DEFAULT_MESSAGE

          model.errors_with_details[attribute] << {error: :presence, message:}
        end

        # This method is used to validate the presence of attributes.
        # @param names [Symbol] The names of the attributes to validate.
        # @param options [Hash] The options for the validation.
        # @option options [String] :message The error message to use if the
        #                                   validation fails.
        # @option options [Symbol] :if A condition to check before validating.
        # @option options [Symbol] :unless A condition to check before
        #                                  validating.
        # @option options [Symbol] :allow_nil Whether to allow nil values.
        # @option options [Symbol] :allow_blank Whether to allow blank values.
        def validates_presence_of(*names, **options)
          validations << Validator.new(Presence, names, options)
        end
      end
    end
  end
end
