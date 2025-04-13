# frozen_string_literal: true

module Zee
  class Model
    class Errors
      include Enumerable

      # @api private
      attr_reader :model

      def initialize(model)
        @model = model
      end

      def add(attribute, type, **)
        details[attribute] << ({type:, **})
      end

      # Return the errors with details for the model.
      # @return [Hash{Symbol => Array<Hash>}]
      def details
        @details ||= Hash.new {|h, k| h[k] = [] }
      end

      # Returns the errors for the model.
      # @return [Hash{Symbol => Array<String>}] The errors for the model.
      def messages
        @messages ||= begin
          hash = Hash.new {|h, k| h[k] = [] }
          details.each_with_object(hash) do |(attr, errors), buffer|
            buffer[attr] ||= []
            errors.each {|error| buffer[attr] << error[:message] }
          end
        end
      end

      # @api private
      def each(&)
        messages.each(&)
      end

      # Clears the errors for the model.
      def clear
        details.clear
        @messages = nil
      end

      # Detect if the model has no errors.
      # @return [Boolean] Whether the model has no errors.
      def empty?
        details.empty?
      end

      # Detect if the model has errors.
      # @return [Boolean] Whether the model has errors.
      def any?
        details.any?
      end

      # Return errors for a given attribute.
      def [](attribute)
        messages[attribute] || []
      end

      # Return the humanized attribute name for the model.
      #
      # @param attribute [Symbol] The attribute to get the name for.
      # @return [String] The humanized attribute name.
      def human_attribute_name(attribute)
        if model.class.respond_to?(:naming)
          model.class.naming.human_attribute_name(attribute, capitalize: false)
        else
          attribute.to_s.tr(UNDERSCORE, SPACE)
        end
      end

      # @api private
      # Return the error message for the model.
      #
      # @param scope [Symbol] The scope of the error message.
      # @param attribute [Symbol] The attribute to get the error message for.
      # @param options [Hash] The options for the error message.
      # @return [String] The error message.
      def build_error_message(scope, attribute, options: {})
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
    end
  end
end
