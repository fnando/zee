# frozen_string_literal: true

module Zee
  class Model
    module Validations
      class Validator
        using Core::Blank

        # The validation module.
        attr_reader :validator

        # The attribute names to validate.
        attr_reader :attributes

        # The options for the validation.
        attr_reader :options

        def initialize(validator, attributes, options)
          @validator = validator
          @attributes = attributes
          @options = options
        end

        def call(model)
          return model.send(validator) if validator.is_a?(Symbol)
          return validator.call(model) if validator.respond_to?(:call)
          return unless attributes

          attributes.each do |attr|
            value = model[attr]

            next if options[:allow_nil] && value.nil?
            next if options[:allow_blank] && value.blank?
            next if options[:if] && !model.send(options[:if])
            next if options[:unless] && model.send(options[:unless])

            validator.validate(model, attr, options)
          end
        end
      end
    end
  end
end
