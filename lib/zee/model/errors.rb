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

      # Returns the full error messages for the model.
      # @return [Array<String>] The full error messages for the model.
      def full_messages
        scope = %w[zee model errors full_message].join(I18n.default_separator)

        messages.each_with_object([]) do |(key, errors), buffer|
          attribute = human_attribute_name(key)
          errors.each do |message|
            buffer << I18n.t(
              scope,
              default: "#{attribute} #{message}",
              attribute:,
              message:
            )
          end
        end
      end

      # Returns the errors for the model.
      # @return [Hash{Symbol => Array<String>}] The errors for the model.
      def messages
        @messages ||= begin
          hash = Hash.new {|h, k| h[k] = [] }
          details.each_with_object(hash) do |(attr, errors), buffer|
            buffer[attr] ||= []
            errors.each do |error|
              error => {type:, **options}
              message = build_error_message(type, attr, options:)
              buffer[attr] << message if message
            end
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
        possible_names = []

        default_name =
          if model.class.respond_to?(:naming)
            scope = [
              :zee, :model, :attributes, model.class.naming.singular, attribute
            ].join(I18n.default_separator)
            possible_names << I18n.t(scope, default: nil)
            model.class.naming.human_attribute_name(
              attribute,
              capitalize: false
            )
          else
            attribute.to_s.tr(UNDERSCORE, SPACE)
          end

        possible_names << I18n.t(
          [:zee, :model, :attributes, attribute].join(I18n.default_separator),
          default: nil
        )
        possible_names << default_name

        possible_names.compact.first
      end

      # @api private
      # Return the error message for the model.
      #
      # @param scope [Symbol] The scope of the error message.
      # @param attribute [Symbol] The attribute to get the error message for.
      # @param options [Hash] The options for the error message.
      # @return [String] The error message.
      # @param [Object, nil] default
      def build_error_message(scope, attribute, default: nil, options: {})
        return format(options[:message], options) if options[:message]

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

        I18n.t(scopes, default: options[:message], **options).compact.first ||
          default ||
          scope.to_s.tr(UNDERSCORE, SPACE)
      end
    end
  end
end
