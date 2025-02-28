# frozen_string_literal: true

module Zee
  module ViewHelpers
    module Form
      using Core::String
      include HTML

      YEAR_MONTH = "%Y-%m"
      ID_CLEANER = "^-a-zA-Z0-9:."
      BUTTON_LABEL = "Button"
      CHECKBOX = "checkbox"
      COLOR = "color"
      DATE = "date"
      DATETIME = "datetime-local"
      MONTH = "month"
      EMAIL = "email"
      NUMBER = "number"
      FILE = "file"
      FORM_END = "</form>"
      HIDDEN = "hidden"
      MULTIPART = "multipart/form-data"
      PASSWORD = "password"
      OFF = "off"
      TEXT = "text"

      # Render a `button` tag.
      # By default, the type is set to `button`.
      #
      # @param content [String] The content of the button.
      # @param type [Symbol] The type of the button.
      # @return [SafeBuffer] The HTML for the button.
      def button_tag(content = BUTTON_LABEL, type: :button, **, &)
        content_tag(:button, content, **, type:, &)
      end

      # Render a `input[type=checkbox]` tag.
      #
      # @param name [String] The name of the field.
      # @param value [String] The value of the field.
      # @return [SafeBuffer] The HTML for the input field.
      def check_box_tag(name, value = "1", **)
        input_field_tag(name, value, **, type: CHECKBOX)
      end

      # Render a `input[type=color]` tag.
      #
      # @param name [String] The name of the field.
      # @param value [String] The value of the field.
      # @return [SafeBuffer] The HTML for the input field.
      def color_field_tag(name, value = nil, **)
        input_field_tag(name, value, **, type: COLOR)
      end

      # Render a `input[type=date]` tag.
      #
      # @param name [String] The name of the field.
      # @param value [String] The value of the field.
      # @return [SafeBuffer] The HTML for the input field.
      def date_field_tag(name, value = Date.today.iso8601, **)
        input_field_tag(name, value, **, type: DATE)
      end

      # Render a `input[type=datetime-local]` tag.
      #
      # @param name [String] The name of the field.
      # @param value [String] The value of the field.
      # @return [SafeBuffer] The HTML for the input field.
      def datetime_field_tag(name, value = Time.now.iso8601, **)
        input_field_tag(name, value, **, type: DATETIME)
      end

      # Render a `input[type=file]` tag.
      #
      # @param name [String] The name of the field.
      # @param value [String] The value of the field.
      # @return [SafeBuffer] The HTML for the input field.
      def file_field_tag(name, value = nil, **)
        input_field_tag(name, value, **, type: FILE)
      end

      # Render a `input[type=email]` field.
      # @param name [String] The name of the field.
      # @param value [String] The value of the field.
      # @param attrs [Hash{Symbol => Object}] The input attributes.
      # @return [SafeBuffer] The HTML for the input field.
      def email_field_tag(name, value = nil, **attrs)
        autocomplete = attrs.delete(:autocomplete)

        unless [false, OFF].include?(autocomplete)
          attrs[:autocomplete] = autocomplete || EMAIL
          attrs[:inputmode] ||= EMAIL
        end

        input_field_tag(name, value, **attrs, type: EMAIL)
      end

      # Render a `form` tag.
      # @param action [String] The action attribute of the form.
      # @param method [Symbol] The method attribute of the form.
      # @param multipart [Boolean] Whether the form is multipart.
      # @param authenticity_token [String] The authenticity token.
      # @param attrs [Hash{Symbol => Object}] The form attributes.
      # @return [SafeBuffer] The HTML for the form.
      #
      # @example Without passing a block
      #   <%= form_tag(action: "/login") %>
      #
      # @example Passing a block
      #   <%= form_tag(action: "/login") do %>
      #     <p><%= email_field_tag :email, params[:email] %></p>
      #     <p><%= submit_tag "Log in" %></p>
      #   <% end %>
      #
      # @example Defining a multipart form
      #   <%= form_tag(action: "/upload", multipart: true) do %>
      #     <p><%= file_field_tag :avatar, params[:avatar] %></p>
      #     <p><%= submit_tag "Upload" %></p>
      #   <% end %>
      #
      # @example Using authenticity token
      #   <%= form_tag(action: "/upload", authenticity_token: "abc") do %>
      #     <p><%= submit_tag "Upload" %></p>
      #   <% end %>
      def form_tag(
        action:,
        method: :post,
        multipart: false,
        authenticity_token: nil,
        **attrs,
        &
      )
        attrs[:enctype] = MULTIPART if multipart
        buffer = SafeBuffer.new
        buffer << tag(:form, action:, method:, **attrs, open: true)

        if authenticity_token && method != :get
          buffer << input_field_tag(
            :authenticity_token,
            authenticity_token,
            type: :hidden
          )
        end

        buffer << capture(&) if block_given?
        buffer << SafeBuffer.new(FORM_END)
        buffer
      end

      # Render a `input[type=text]` field.
      # @param name [String] The name of the field.
      # @param value [String] The value of the field.
      # @return [SafeBuffer] The HTML for the input field.
      def text_field_tag(name, value = nil, **)
        input_field_tag(name, value, **, type: TEXT)
      end

      # Render a `input[type=hidden]` field.
      # @param name [String] The name of the field.
      # @param value [String] The value of the field.
      # @return [SafeBuffer] The HTML for the input field.
      def hidden_field_tag(name, value = nil, **)
        input_field_tag(name, value, **, type: HIDDEN)
      end

      # Render a `label` tag.
      # @param name [String] The name of the field.
      # @param text [Object, nil] The label text.
      # @param attrs [Hash{Symbol => Object}] The label attributes.
      # @return [SafeBuffer] The HTML for the label.
      def label_tag(name, text = nil, **attrs)
        name = name.to_s

        attrs[:for] ||= name_to_id(name)
        text ||= (name[/\[([a-z_]+)\]/, 1] || name).humanize
        content_tag(:label, text, **attrs)
      end

      # Render a `input[type=month]` field.
      # @param name [String] The name of the field.
      # @param value [String] The value of the field.
      # @return [SafeBuffer] The HTML for the input field.
      def month_field_tag(name, value = Date.today, **)
        value = value.strftime(YEAR_MONTH) if value.respond_to?(:strftime)
        input_field_tag(name, value, **, type: MONTH)
      end

      # Render a `input[type=number]` field.
      # @param name [String] The name of the field.
      # @param value [String] The value of the field.
      # @param attrs [Hash{Symbol => Object}] The input attributes.
      # @option attrs [Range] :in The range of numbers.
      # @return [SafeBuffer] The HTML for the input field.
      def number_field_tag(name, value = nil, **attrs)
        within = attrs.delete(:in)
        attrs[:min], attrs[:max] = within.minmax if within.is_a?(Range)

        input_field_tag(name, value, **attrs, type: NUMBER)
      end

      # Render a `input[type=password]` field.
      # @param name [String] The name of the field.
      # @param value [String] The value of the field.
      # @param attrs [Hash{Symbol => Object}] The input attributes.
      # @return [SafeBuffer] The HTML for the input field.
      #
      # @example Using the `autocomplete` attribute
      #   password_field_tag :password, autocomplete: :current_password
      #   password_field_tag :password, autocomplete: :new_password
      #   password_field_tag :password, autocomplete: :one_time_code
      def password_field_tag(name, value = nil, **attrs)
        attrs[:autocomplete] ||= PASSWORD

        input_field_tag(name, value, **attrs, type: PASSWORD)
      end

      # Render a `input` field.
      # @param name [String] The name of the field.
      # @param value [String] The value of the field.
      # @param type [String] The type of the field.
      # @param attrs [Hash{Symbol => Object}] The input attributes.
      # @return [SafeBuffer] The HTML for the input field.
      def input_field_tag(name, value = nil, type: TEXT, **attrs)
        name = name.to_s
        id = name_to_id(name) unless name.blank?

        if attrs[:autocomplete]
          attrs[:autocomplete] = attrs[:autocomplete].to_s.tr(UNDERSCORE, DASH)
        end

        tag(:input, name:, value:, type:, id:, **attrs)
      end

      # @private
      def name_to_id(name)
        name.to_s.delete(CLOSE_SQUARE_BRACKET).tr(ID_CLEANER, UNDERSCORE)
      end
    end
  end
end
