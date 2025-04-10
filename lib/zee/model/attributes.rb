# frozen_string_literal: true

module Zee
  class Model
    module Attributes
      def self.included(target)
        target.extend ClassMethods
      end

      module ClassMethods
        def inherited(subclass)
          subclass.attributes.merge!(attributes)
          super
        end

        # This method is used to define an attribute for the model.
        # @param name [Symbol] The name of the attribute.
        # @param type [Symbol] The type of the attribute. Default is :string.
        # @param default [Object] The default value of the attribute.
        #
        # @example Defining multiple attributes
        # class User
        #   include Zee::Model::Attributes
        #
        #   attribute :name
        #   attribute :age, :integer
        #   attribute :status, default: "pending"
        # end
        #
        # @example Using custom type
        # class User
        #   include Zee::Model::Attributes
        #
        #   attribute :name, :uppercase, default: "UNKNOWN"
        #
        #   private def coerce_to_uppercase(value)
        #     value.to_s.upcase
        #   end
        # end
        def attribute(name, type = :string, default: nil)
          attributes[name] = {type:, default:}
          define_method(name) do
            instance_variable_get(:"@#{name}") || default
          end

          define_method("#{name}=") do |value|
            value = send(:"coerce_to_#{type}", value) unless value.nil?
            instance_variable_set(:"@#{name}", value)
          end
        end

        def attributes
          @attributes ||= {}
        end
      end

      def initialize(**attrs)
        attrs.each {|name, value| public_send(:"#{name}=", value) }
      end

      # This method is used to get all attributes of the model.
      # @return [Hash] A hash containing all attributes and their values.
      def attributes
        self.class.attributes.keys.each_with_object({}) do |name, buffer|
          buffer[name] = public_send(name)
        end
      end

      # This method is used to get the value of an attribute.
      # @param name [Symbol] The name of the attribute.
      # @return [Object] The value of the attribute.
      def [](name)
        public_send(name)
      end

      # This method is used to set the value of an attribute.
      # @param name [Symbol] The name of the attribute.
      # @param value [Object] The value of the attribute.
      def []=(name, value)
        public_send("#{name}=", value)
      end

      private def coerce_to_string(value)
        value.to_s
      end

      private def coerce_to_integer(value)
        value.to_i
      end
    end
  end
end
