# frozen_string_literal: true

module Zee
  class Model
    module Attributes
      # @api private
      FALSE_VALUES =
        [0, "0", false, "false", "FALSE", nil, "off", "OFF", "no", "NO"]
        .freeze

      # @api private
      def self.included(target)
        target.extend ClassMethods
      end

      module ClassMethods
        # @api private
        def inherited(subclass)
          subclass.attributes.merge!(attributes)
          super
        end

        # This method is used to define an attribute for the model.
        # @param name [Symbol] The name of the attribute.
        # @param type [Symbol] The type of the attribute. Default is :string.
        # @param default [Object] The default value of the attribute.
        #
        # ## Coerce To Types
        #
        # - `:integer` converts objects to integers using
        #   [`Integer()`](https://ruby-doc.org/3.4.1/Kernel.html#method-i-Integer).
        # - `:boolean` converts [0, "0", "false", "FALSE", nil] to `false`. All
        #   other values are converted to `true`.
        # - `:date` converts objects to dates using `Date.parse`.
        # - `:float` converts objects to floats using `Float(value)`
        # - `:decimal` converts objects to big decimal instances using
        #   `BigDecimal(value, precision)`. The default precision is
        #   `Float::DIG + 1`.
        #
        # @example Defining multiple attributes
        #   ```ruby
        #   class User
        #     include Zee::Model::Attributes
        #
        #     attribute :name
        #     attribute :age, :integer
        #     attribute :status, default: "pending"
        #   end
        #   ```
        #
        # @example Using custom type
        #   ```ruby
        #   class User
        #     include Zee::Model::Attributes
        #
        #     attribute :name, :uppercase, default: "UNKNOWN"
        #
        #     private def coerce_to_uppercase(value)
        #       value.to_s.upcase
        #     end
        #   end
        #   ```
        def attribute(name, type = :string, default: nil, **)
          attributes[name] = {type:, default:}
          define_method(name) do
            instance_variable_get(:"@#{name}") || default
          end

          define_method("#{name}=") do |value|
            value = send(:"coerce_to_#{type}", value, **) unless value.nil?
            instance_variable_set(:"@#{name}", value)
          end
        end

        # Hold all attributes defined in a model.
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

      # @api private
      private def coerce_to_string(value)
        value.to_s
      end

      # @api private
      private def coerce_to_integer(value)
        Integer(value)
      end

      # @api private
      private def coerce_to_boolean(value)
        !FALSE_VALUES.include?(value)
      end

      # @api private
      private def coerce_to_date(value)
        case value
        when Date
          value
        when Time
          value.to_date
        when Integer
          Time.at(value).to_date
        when String
          Date.parse(value)
        else
          raise ArgumentError, "invalid date value: #{value.inspect}"
        end
      end

      # @api private
      private def coerce_to_time(value)
        case value
        when Time
          value
        when Date
          value.to_time
        when Integer
          Time.at(value)
        when String
          Time.parse(value)
        else
          raise ArgumentError, "invalid time value: #{value.inspect}"
        end
      end

      # @api private
      def coerce_to_float(value)
        Float(value)
      end

      # @api private
      def coerce_to_decimal(value, precision: Float::DIG + 1)
        case value
        when BigDecimal
          value
        else
          BigDecimal(value.to_s, precision)
        end
      end
    end
  end
end
