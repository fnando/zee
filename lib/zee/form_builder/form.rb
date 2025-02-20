# frozen_string_literal: true

module Zee
  class FormBuilder
    class Form < Base
      # @return [FormBuilder] the form's builder.
      attr_reader :builder

      def initialize(builder:)
        super()
        @builder = builder
      end

      def view_template(&)
        form(
          action: builder.url,
          method: builder.options.fetch(:method, :post)
        ) { instance_eval(&) }
      end

      # Define a form field.
      # A field is composed of a label, hint, error and an input element.
      # @param name [Symbol] the field's name. Must match the object's
      #                      attribute, accessible via `object[name]`
      #                      or `object.name`.
      # @param [Hash{Symbol => Object}] options
      # @option options [Symbol] :type the field's type. Can be one of the
      #                                registered components.
      def field(name, **options)
        type = options.delete(:type) || infer_type(name)

        render builder.layout.new(
          input: send(:"build_#{type}_field", name, **options),
          label: build_label(name, options.delete(:label)),
          hint: build_hint(name, options.delete(:hint))
        )
      end

      # Define a text field.
      # @param name [Symbol] the field's name.
      # @see FormBuilder
      def text_field(name, **)
        render build_text_field(name, **)
      end

      # Define a color field.
      # @param name [Symbol] the field's name.
      # @see FormBuilder
      def color_field(name, **)
        render build_color_field(name, **)
      end

      # Define a email field.
      # @param name [Symbol] the field's name.
      # @see FormBuilder
      def email_field(name, **)
        render build_email_field(name, **)
      end

      # Define a checkbox field.
      # @param name [Symbol] the field's name.
      # @see FormBuilder
      # @param [String] checked_value
      # @param [String] unchecked_value
      def check_box(name, checked_value: "1", unchecked_value: "0", **)
        render build_check_box_field(
          name,
          checked_value:,
          unchecked_value:,
          **
        )
      end

      # Define a phone field.
      # @param name [Symbol] the field's name.
      # @see FormBuilder
      def phone_field(name, **)
        render build_phone_field(name, **)
      end
      alias tel_field phone_field

      # @private
      private def build_text_field(name, **options)
        build_input(name:, type: :text, options:)
      end

      # @private
      private def build_check_box_field(
        name,
        checked_value: "1",
        unchecked_value: "0",
        **options
      )
        id = options[:id] || id_for(name)
        value = options[:value] || value_for(name)
        name = options[:name] || name_for(name)
        Checkbox.new(
          **options,
          id:,
          value:,
          name:,
          checked_value:,
          unchecked_value:
        )
      end

      # @private
      private def build_color_field(name, **options)
        build_input(name:, type: :color, options:)
      end

      # @private
      private def build_tel_field(name, **options)
        options[:autocapitalize] = :off
        options[:autocomplete] = :tel
        options[:inputmode] = :tel
        build_input(name:, type: :tel, options:)
      end

      # @private
      private def build_email_field(name, **options)
        options[:autocapitalize] = :off
        options[:autocomplete] = :email
        options[:inputmode] = :email
        build_input(name:, type: :email, options:)
      end

      # Define a field label.
      # @param name [Symbol] the field's name.
      # @param text [String] the label's text.
      def label(name, text = nil, **)
        render build_label(name, text, **)
      end

      # Define a field label.
      # @param name [Symbol] the hint's name. Will be used to fetch the hint's
      #                      translation.
      # @param text [String] the label's text.
      def hint(name, text = nil, **)
        render build_hint(name, text, **)
      end

      # @private
      private def build_label(name, text = nil, **options)
        Label.new(
          text:,
          **options,
          for: options[:for] || id_for(name)
        )
      end

      # @private
      private def build_hint(_name, text = nil, **)
        Hint.new(text:, **)
      end

      # @private
      private def build_input(name:, type:, options:)
        id = options[:id] || id_for(name)
        value = options[:value] || value_for(name)
        name = options[:name] || name_for(name)

        Input.new(**options, type:, name:, id:, value:)
      end
    end
  end
end
