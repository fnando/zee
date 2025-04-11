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
