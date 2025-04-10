# frozen_string_literal: true

module Zee
  class Model
    module Validations
      def self.included(target)
        target.extend ClassMethods
      end

      # Return the humanized attribute name for the model.
      # @param model [Model] The model to get the attribute name for.
      # @param attribute [Symbol] The attribute to get the name for.
      # @return [String] The humanized attribute name.
      def self.human_attribute(model, attribute)
        if model.class.respond_to?(:naming)
          model.class.naming.human_attribute_name(attribute, capitalize: false)
        else
          attribute.to_s.tr(UNDERSCORE, SPACE)
        end
      end

      # Return the error message for the model.
      # @param scope [Symbol] The scope of the error message.
      # @param model [Model] The model to get the error message for.
      # @param attribute [Symbol] The attribute to get the error message for.
      # @param options [Hash] The options for the error message.
      # @return [String] The error message.
      def self.error_message(scope, model, attribute, options: {})
        scopes = []

        if model.class.respond_to?(:naming)
          scopes << [
            :zee,
            :model,
            :errors,
            model.class.naming.singular,
            attribute,
            scope
          ].join(I18n.default_separator)
        end

        scopes << [:zee, :model, :errors, scope].join(I18n.default_separator)

        I18n.t(scopes, default: nil, **options).compact.first
      end

      module ClassMethods
        include Presence
        include Confirmation
        include Acceptance
        include Format
        include Inclusion
        include Exclusion
        include Size

        # @return [Array<Validator>] The list of validations for the model.
        def validations
          @validations ||= []
        end

        def inherited(subclass)
          subclass.validations.push(*validations)
          super
        end
      end

      # Runs all validations for the model.
      # @return [Boolean] Whether the model is valid.
      def valid?
        @errors = nil
        errors_with_details.clear

        self.class.validations.each {|validator| validator.call(self) }
        errors.empty?
      end

      # Runs all validations for the model.
      # @return [Boolean] Whether the model is invalid.
      def invalid?
        !valid?
      end

      # Returns the errors for the model.
      # @return [Hash{Symbol => Array<String>}] The errors for the model.
      def errors
        @errors ||= begin
          hash = Hash.new {|h, k| h[k] = [] }
          errors_with_details.each_with_object(hash) do |(attr, errors), buffer|
            buffer[attr] ||= []
            errors.each {|error| buffer[attr] << error[:message] }
          end
        end
      end

      # Returns the errors with details for the model.
      # @return [Hash{Symbol => Array<Hash>}]
      def errors_with_details
        @errors_with_details ||= Hash.new {|h, k| h[k] = [] }
      end
    end
  end
end
