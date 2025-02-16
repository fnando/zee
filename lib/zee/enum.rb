# frozen_string_literal: true

module Zee
  # Create an enum object.
  # @param args [Array<Symbol>] List of keys.
  # @param kwargs [Hash] Hash of keys and values.
  # @return [Object] An enum object.
  #
  # @example
  #   Status = Zee::Enum(:on, :off)
  #   Status.to_a # => [:on, :off]
  #   Status.to_h # => {on: "on", off: "off"}
  #   Status[0] # => "on"
  #   Status[:on] # => "on"
  #   Status.keys # => [:on, :off]
  #   Status.values # => ["on", "off"]
  #   Status.each {|key, value| p [key, value]}
  #   Status.each_key {|key| p key}
  #   Status.each_value {|value| p value}
  def self.Enum(*args, **kwargs) # rubocop:disable Naming/MethodName
    props = (kwargs.any? ? kwargs : args.zip(args.map(&:to_s)).to_h).freeze
    keys = props.keys.freeze
    values = props.values.freeze

    klass = Class.new do
      attr_reader(*keys)

      def self.name
        "Zee::Enum"
      end

      def self.inspect
        "#<Zee::Enum class>"
      end

      def self.to_s
        inspect
      end

      define_method :initialize do
        props.each do |key, value|
          instance_variable_set(:"@#{key}", value.freeze)
        end
      end

      define_method :to_a do
        keys
      end

      define_method :to_h do
        props
      end

      define_method :[] do |index|
        key = index.instance_of?(Integer) ? keys[index] : index

        unless keys.include?(key)
          raise ArgumentError, "Invalid enum index: #{index.inspect}"
        end

        props[key]
      end

      define_method :keys do
        keys
      end

      define_method :values do
        values
      end

      define_method :inspect do
        "#<Zee::Enum #{props.map do |key, value|
          "#{key}=#{value.inspect}"
        end.join(' ')}>"
      end
      alias_method :to_s, :inspect

      define_method :each_key do |&block|
        keys.each(&block)
      end

      define_method :each_value do |&block|
        values.each(&block)
      end

      define_method :each do |&block|
        props.each(&block)
      end
    end

    klass.new.freeze
  end
end
