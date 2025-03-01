# frozen_string_literal: true

module Zee
  class FormBuilder
    using Core::String

    # @private
    # The values that will be used to mark a `input[type=checkbox]` as checked.
    TRUTHY_VALUES = %w[1 true yes TRUE YES].freeze

    # @private
    ERROR = "error"

    # @return [Object] The field value source.
    attr_reader :object

    # @return [Symbol, String] The form namespace name.
    attr_reader :object_name

    # @return [Object] The helpers context.
    attr_reader :context

    # The form builder's most common usage is by using the `form_for` method.
    # @see ViewHelpers::Form#form_for
    def initialize(object:, context:, object_name:, **)
      @object = object
      @object_name = object_name
      @context = context
    end

    # Render a `input[type=text]` field.
    # @param attr [String, Symbol] The attribute name.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#text_field_tag
    def text_field(attr, **attrs)
      build_input(:text, attr, **attrs)
    end

    # Render a `input[type=color]` field.
    # @param attr [String, Symbol] The attribute name.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#color_field_tag
    def color_field(attr, **attrs)
      build_input(:color, attr, **attrs)
    end

    # Render a `input[type=date]` field.
    # @param attr [String, Symbol] The attribute name.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#date_field_tag
    def date_field(attr, **attrs)
      build_input(:date, attr, **attrs)
    end

    # Render a `input[type=datetime]` field.
    # @param attr [String, Symbol] The attribute name.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#datetime_field_tag
    def datetime_field(attr, **attrs)
      build_input(:datetime, attr, **attrs)
    end

    # Render a `input[type=file]` field.
    # @param attr [String, Symbol] The attribute name.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#text_field_tag
    def file_field(attr, **attrs)
      build_input(:file, attr, **attrs)
    end

    # Render a `input[type=email]` field.
    # @param attr [String, Symbol] The attribute name.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#email_field_tag
    def email_field(attr, **attrs)
      build_input(:email, attr, **attrs)
    end

    # Render a `input[type=hidden]` field.
    # @param attr [String, Symbol] The attribute name.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#hidden_field_tag
    def hidden_field(attr, **attrs)
      build_input(:hidden, attr, **attrs)
    end

    # Render a `input[type=month]` field.
    # @param attr [String, Symbol] The attribute name.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#month_field_tag
    def month_field(attr, **attrs)
      build_input(:month, attr, **attrs)
    end

    # Render a `input[type=number]` field.
    # @param attr [String, Symbol] The attribute name.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#number_field_tag
    def number_field(attr, **attrs)
      build_input(:number, attr, **attrs)
    end

    # Render a `input[type=password]` field.
    # @param attr [String, Symbol] The attribute name.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#password_field_tag
    def password_field(attr, **attrs)
      build_input(:password, attr, **attrs)
    end

    # Render a `input[type=tel]` field.
    # @param attr [String, Symbol] The attribute name.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#phone_field_tag
    def phone_field(attr, **attrs)
      build_input(:phone, attr, **attrs)
    end

    # Render a `input[type=radio]` field.
    # @param attr [String, Symbol] The attribute name.
    # @param value [String] The input value.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#radio_button_tag
    def radio_button(attr, value, **attrs)
      attrs = add_error_class(attr, attrs)
      value = value.to_s
      checked = value == value_for(attr).to_s
      @context.radio_button_tag name_for(attr), value, checked:, **attrs
    end

    # Render a `input[type=search]` field.
    # @param attr [String, Symbol] The attribute name.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#search_field_tag
    def search_field(attr, **attrs)
      build_input(:search, attr, **attrs)
    end

    # Render a `select` field.
    # @param attr [String, Symbol] The attribute name.
    # @param options [Array<Object>] The `select` options.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#select_tag
    def select(attr, options = [], **attrs)
      attrs = add_error_class(attr, attrs)
      @context.select_tag name_for(attr),
                          options,
                          **attrs,
                          selected: value_for(attr)
    end

    # Render a `textarea` field.
    # @param attr [String, Symbol] The attribute name.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#textarea_tag
    def textarea(attr, **attrs)
      build_input(:textarea, attr, **attrs)
    end
    alias text_area textarea

    # Render a `input[type=time]` field.
    # @param attr [String, Symbol] The attribute name.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#time_field_tag
    def time_field(attr, **attrs)
      build_input(:time, attr, **attrs)
    end

    # Render a `input[type=url]` field.
    # @param attr [String, Symbol] The attribute name.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#url_field_tag
    def url_field(attr, **attrs)
      build_input(:url, attr, **attrs)
    end

    # Render a `input[type=checkbox]` field.
    #
    # This method will render a hidden field with the same name as the checkbox,
    # so a value is sent when the checkbox isn't checked.
    #
    # If `value` is provided, the checkbox will enter the collection mode.
    # This means:
    #
    # - the `input[type=hidden]` won't be rendered
    # - the `name` attribute will be suffixed with `[]`, e.g. `post[tags][]`.
    #
    # You can also prevent the hidden field from being rendered by passing `nil`
    # as the `unchecked_value`.
    #
    # @param attr [String, Symbol] The attribute name.
    # @param checked_value [String] The value that'll be used when the input is
    #                               checked.
    # @param unchecked_value [String] The value that'll be used when the input
    #                                 is unchecked.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#checkbox_tag
    # @param [Object, nil] value
    def checkbox(
      attr,
      value = nil,
      checked_value: "1",
      unchecked_value: "0",
      **attrs
    )
      attrs = add_error_class(attr, attrs)
      collection = value.to_s.present?
      current_value = value_for(attr)

      if collection
        attrs[:id] ||= id_for(attr, value)
        checked_value = value.to_s
        checked = Array(current_value).map(&:to_s).include?(checked_value)
      else
        current_value = current_value.to_s

        checked = current_value == checked_value ||
                  TRUTHY_VALUES.include?(current_value)
      end

      buffer = SafeBuffer.new

      unless unchecked_value.nil? || collection
        buffer << @context.hidden_field_tag(name_for(attr), unchecked_value)
      end

      buffer << @context.checkbox_tag(
        name_for(attr, collection:),
        checked_value,
        checked:,
        **attrs
      )
      buffer
    end
    alias check_box checkbox

    # Render a group of `input[type=checkbox]` fields.
    # This method also renders labels for each checkbox.
    #
    # You can provide an array of arrays, where each inner array contains the
    # key and the label. If you provide only the key (i.e. a flat array), the
    # label will be generated using I18n. The scope will be
    # `[:form, object_name, attribute, :_values, value]`. For instance, say you
    # have a `Theme` model and you're rendering a checkbox group for the `color`
    # attribute. You must have a translation defined as follows:
    #
    #     en:
    #       forms:
    #         theme:
    #           color:
    #             _values:
    #               red: "Red"
    #               green: "Green"
    #
    # @param attr [String, Symbol] The attribute name.
    # @param items [Array<Array<Object, Object>>] The checkbox items.
    # @return [SafeBuffer]
    #
    # @example Providing both values and labels
    #   checkbox_group :color, [["red", "Red"], ["green", "Green"]]
    #   #=> <div class="field-group">
    #   #=>   <label for="user_color_red">Red</label>
    #   #=>   <input type="checkbox" name="user[color][]" value="red"
    #   #=>          id="user_color_red">
    #   #=> </div>
    #   #=> <div class="field-group">
    #   #=>   <label for="user_color_green">Green</label>
    #   #=>   <input type="checkbox" name="user[color][]" value="green"
    #   #=>          id="user_color_green">
    #   #=> </div>
    #
    # @example Providing only values; labels will using I18n instead.
    #   checkbox_group :color, ["red", "green"]
    def checkbox_group(attr, items)
      buffer = SafeBuffer.new

      items.each do |item|
        value, label = Array(item)
        label ||= translation_for(
          :"_values.#{value}",
          attr,
          default: value.to_s.humanize
        )

        hint_text = translation_for(:"_hints.#{value}", attr, default: nil)
        hint = @context.tag(:br) + hint(attr, hint_text) if hint_text

        buffer << @context.content_tag(:div, class: "field-group") do
          checkbox(attr, value) +
            @context.content_tag(:span, label([:tags, value], label) + hint,
                                 class: "field-group-heading")
        end
      end

      buffer
    end

    # Render a submit button field.
    # @param label [String, nil] The button label.
    def submit(label = "Submit", **, &)
      @context.button_tag(label, **, type: "submit", &)
    end

    # Render a `label` tag.
    #
    # This method will generate a label tag for the provided attribute. If the
    # `text` argument is not provided, a I18n translation will be used instead,
    # defaulting to a humanized version of the attribute name.
    #
    # The scope for the translation will be
    # `[:form, object_name, attribute, :label]`. Say you have a `User` model and
    # you're rendering a label for the `name` attribute. You must have a
    # translation defined as follows:
    #
    #     en:
    #       forms:
    #         user:
    #           name:
    #             label: "Your Name"
    #
    # @param attr [String, Symbol] The attribute name.
    # @param text [String,  SafeBuffer, nil] The label text. When not provided,
    #                                        a label generated out of the
    #                                        attribute name will be used
    #                                        instead.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#label_tag
    def label(attr, text = nil, **attrs, &)
      text ||= Array(attr).last.to_s.humanize
      text = translation_for :label, attr, default: text
      attrs = add_error_class(attr, attrs)
      @context.label_tag(id_for(*Array(attr)), text, **attrs, &)
    end

    # Render a hint message.
    #
    # This method will generate a hint element for the provided attribute. If
    # the `text` argument is not provided, a I18n translation will be used
    # instead.
    #
    # The scope for the translation will be
    # `[:form, object_name, attribute, :hint]`. Say you have a `User` model and
    # you're rendering a hint for the `name` attribute. You must have a
    # translation defined as follows:
    #
    #     en:
    #       forms:
    #         user:
    #           name:
    #             hint: "This is how users will see you in the site."
    #
    # @param attr [String, Symbol] The attribute name.
    # @param text [String,  SafeBuffer, nil] The label text. When not provided,
    #                                        a label generated out of the
    #                                        attribute name will be used
    #                                        instead.
    # @param attrs [Hash{Symbol => Object}] The HTML attributes.
    # @see ViewHelpers::Form#label_tag
    def hint(attr, text = nil, **attrs)
      text ||= translation_for :hint, attr, default: EMPTY_STRING
      attrs = add_error_class(attr, attrs, :hint)
      @context.content_tag(:span, text, **attrs) unless text.blank?
    end

    # Retrieve the error messages for the provided attribute.
    # @param attr [String, Symbol] The attribute name.
    # @return [Array<String>]
    def error_messages_for(attr)
      errors = value_for(:errors) || {}
      Array(errors[attr])
    end

    # Check if the provided attribute has any error.
    # @param attr [String, Symbol] The attribute name.
    # @return [Boolean]
    def error?(attr)
      error_messages_for(attr).any?
    end

    # Render the error message for the provided attribute.
    # @param attr [String, Symbol] The attribute name.
    # @param attrs [Hash] The HTML attributes.
    # @return [SafeBuffer, nil]
    def error(attr, **attrs)
      error = error_messages_for(attr).first

      return unless error

      @context.content_tag(
        :span,
        error,
        **attrs,
        class: @context.class_names(attrs[:class], ERROR)
      )
    end

    # @private
    # Generate `name` attribute for the provided attribute.
    # The final form will be something like `user[name]`.
    # @param attr [String, Symbol] The attribute name.
    # @param collection [Boolean] Whether the attribute is a collection.
    # @return [String]
    def name_for(attr, collection: false)
      suffix = "[]" if collection
      "#{object_name}[#{attr}]#{suffix}"
    end

    # @private
    # Generate `id` attribute for the provided attribute.
    # @return [String]
    def id_for(attr, value = nil)
      @context.normalize_id([name_for(attr), value].compact.join(UNDERSCORE))
    end

    # @private
    # Retrieve the value out of the object source.
    # If the object responds to `#[](attr)`, that will be used. Otherwise, we'll
    # call `object.attr`.
    # @return [Object]
    def value_for(attr)
      if object.respond_to?(:[])
        object[attr]
      elsif object.respond_to?(attr)
        object.public_send(attr)
      end
    end

    # @private
    # @example
    #   translation_for(:label, :name, default: "Name")
    def translation_for(scope, attr, default: nil)
      I18n.t(scope, scope: [:form, object_name, attr], default:)
    end

    # @private
    def add_error_class(attr, attrs, *other_classes)
      {
        **attrs,
        class: @context.class_names(
          attrs.delete(:class),
          {invalid: error?(attr)},
          *other_classes
        )
      }
    end

    # @private
    def build_input(type, attr, **attrs)
      attrs = add_error_class(attr, attrs)
      attrs[:placeholder] ||=
        translation_for(:placeholder, attr, default: false)

      helper_name = :"#{type}_field_tag"
      helper_name = :textarea_tag if type == :textarea

      @context.send helper_name,
                    name_for(attr),
                    value_for(attr),
                    **attrs
    end
  end
end
