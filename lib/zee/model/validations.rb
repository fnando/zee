# frozen_string_literal: true

module Zee
  class Model
    module Validations
      def self.included(target)
        target.extend ClassMethods
      end

      module ClassMethods
        include Presence
        include Confirmation
        include Acceptance
        include Format
        include Inclusion
        include Exclusion
        include Size
        include Numericality

        # @return [Array<Validator>] The list of validations for the model.
        def validations
          @validations ||= []
        end

        def inherited(subclass)
          subclass.validations.push(*validations)
          super
        end

        # Define a custom validation method.
        #
        # @param validator [Symbol, #call(model)] The name of the validation
        #                                         method.
        # @param options [Hash] The options for the validation.
        #
        # @example
        #   validate :my_custom_validation
        #   validate MyValidator
        #   validate {|model| model.errors.add(:attr, :invalid, "is invalid") }
        def validate(validator = nil, **options, &block)
          if !validator && !block
            raise ArgumentError,
                  "either a validator or a block must be provided"
          end

          validator = block if block
          validations << Validator.new(validator, nil, options)
        end
      end

      # Returns the errors for the model.
      # @return [Hash{Symbol => Array<String>}] The errors for the model.
      def errors
        @errors ||= Errors.new(self)
      end

      # Runs all validations for the model.
      # @return [Boolean] Whether the model is valid.
      def valid?
        errors.clear
        self.class.validations.each {|validator| validator.call(self) }
        errors.empty?
      end

      # Runs all validations for the model.
      # @return [Boolean] Whether the model is invalid.
      def invalid?
        !valid?
      end
    end
  end
end
