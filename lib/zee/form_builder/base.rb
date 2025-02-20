# frozen_string_literal: true

module Zee
  class FormBuilder
    def self.inferrable_types
      @inferrable_types ||= [
        ->(name) { :email if name.include?("email") },
        ->(name) { :tel if name.include?("phone") },
        ->(name) { :color if name.include?("color") }
      ]
    end

    class Base < Phlex::HTML
      # Infer the input's type out of its name.
      # New types can be added to the {FormBuilder.inferrable_types} constant.
      #
      # @param name [Symbol] the input's name.
      # @return [Symbol] the input's type.
      def infer_type(name)
        name = name.to_s

        FormBuilder.inferrable_types.each do |callable|
          type = callable.call(name)
          return type if type
        end

        :text
      end

      def process_attributes(options)
        data = data_attributes(options.delete(:data))

        options.merge(data)
      end

      def data_attributes(data)
        return {} unless data

        data.each_with_object({}) do |(key, value), hash|
          hash["data-#{key}"] = value
        end
      end

      # Generate a field name.
      # If the form has a name, it will be prefixed to the field name.
      # @param name [Symbol] the field's name.
      # @param array [Boolean] whether the field is an array.
      # @return [String] the field's name.
      #
      # @example
      #   form = Zee::FormBuilder.new(object: nil, url: "/")
      #   form.name_for(:name)
      #   #=> "name"
      #
      # @example
      #   form = Zee::FormBuilder.new(object: nil, url: "/", as: :user)
      #   form.name_for(:name)
      #   #=> "user[name]"
      #
      # @example
      #   form = Zee::FormBuilder.new(object: nil, url: "/")
      #   form.name_for(:tags, array: true)
      #   #=> "tags[]"
      def name_for(name, array: false)
        suffix = "[]" if array

        builder.as ? "#{builder.as}[#{name}]#{suffix}" : "#{name}#{suffix}"
      end

      # Generate a new id attribute for a field.
      # @param name [Symbol] the field's name.
      # @param index [Integer] the field's index.
      # @return [String] the field's id attribute.
      #
      # @example
      #   form = Zee::FormBuilder.new(object: nil, url: "/")
      #   form.id_for(:name)
      #   #=> "name"
      #
      # @example
      #   form = Zee::FormBuilder.new(object: nil, url: "/", as: :user)
      #   form.id_for(:name)
      #   #=> "user-name"
      #
      # @example
      #   form = Zee::FormBuilder.new(object: nil, url: "/", as: :user)
      #   form.id_for(:skills, index: 0)
      #   #=> "skills-0"
      def id_for(name, index: nil)
        [builder.as, name, index].compact.join("-")
      end

      # Get the value for a field.
      # @param name [Symbol] the field's name.
      # @return [Object] the field's value.
      def value_for(name)
        builder.object ? builder.object[name] : ""
      end

      # Define the `class` attribute.
      #
      # @param args [Array<Object>] the classes to be added.
      # @param kwargs [Hash{Symbol => Object}] the classes to be added.
      #
      # Use cases:
      # - any empty values (nil or empty string) will be ignored
      # - any falsy values will be ignored
      #
      # @example
      #   class_names("foo", "bar")
      #   #=> "foo bar"
      #
      # @example
      #   class_names("foo", nil, "bar")
      #   #=> "foo bar"
      #
      # @example
      #   class_names("foo", false, "bar")
      #   #=> "foo bar"
      #
      # @example
      #   class_names("foo", "", "bar")
      #   #=> "foo bar"
      #
      # @example
      #   class_names("foo", bar: true)
      #   #=> "foo bar"
      #
      # @example
      #   class_names("foo", bar: true, baz: false)
      #   #=> "foo bar"
      def class_names(*args, **kwargs)
        classes = args.flatten.select { _1 && _1.to_s != "" }
        classes = kwargs.each_with_object(classes) do |(k, v), buffer|
          buffer << k if v && v.to_s != ""
        end

        classes.map(&:to_s).uniq.join(" ")
      end
    end
  end
end
