# frozen_string_literal: true

module Zee
  class Model
    module Validations
      include Presence

      def self.included(target)
        target.extend ClassMethods
      end

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

        def validations
          @validations ||= []
        end

        def inherited(subclass)
          subclass.validations.push(*validations)
          super
        end
      end

      def valid?
        @errors = nil
        errors_with_details.clear

        self.class.validations.each {|validator| validator.call(self) }
        errors.empty?
      end

      def invalid?
        !valid?
      end

      def errors
        @errors ||=
          errors_with_details.each_with_object({}) do |(attr, errors), buffer|
            buffer[attr] ||= []
            errors.each {|error| buffer[attr] << error[:message] }
          end
      end

      def errors_with_details
        @errors_with_details ||= Hash.new {|h, k| h[k] = [] }
      end
    end
  end
end
