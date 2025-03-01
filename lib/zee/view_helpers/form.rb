# frozen_string_literal: true

module Zee
  module ViewHelpers
    module Form
      using Core::String
      include HTML

      # @private
      BUTTON_LABEL = "Button"

      # @private
      CHECKBOX = "checkbox"

      # @private
      COLOR = "color"

      # @private
      DATE = "date"

      # @private
      DATETIME = "datetime-local"

      # @private
      DOUBLE_ZERO = "00"

      # @private
      EMAIL = "email"

      # @private
      FILE = "file"

      # @private
      FORM_END = "</form>"

      # @private
      HIDDEN = "hidden"

      # @private
      ID_CLEANER = "^-a-zA-Z0-9:."

      # @private
      INPUT_FILE_RE = /<input.*?type="file"/

      # @private
      MONTH = "month"

      # @private
      MULTIPART = "multipart/form-data"

      # @private
      NUMBER = "number"

      # @private
      OFF = "off"

      # @private
      PASSWORD = "password"

      # @private
      RADIO = "radio"

      # @private
      RANGE = "range"

      # @private
      SEARCH = "search"

      # @private
      TEL = "tel"

      # @private
      TEXT = "text"

      # @private
      TIME = "time"

      # @private
      TIME_WITH_SECONDS = "%H:%M:%S"

      # @private
      TIME_WITHOUT_SECONDS = "%H:%M"

      # @private
      URL = "url"

      # @private
      URL_PATTERN = "^https?://"

      # @private
      YEAR_MONTH = "%Y-%m"

      # @private
      YEAR_MONTH_DAY = "%Y-%m-%d"

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
      # @param name [String, Symbol] The name of the field.
      # @param value [String] The value of the field.
      # @return [SafeBuffer] The HTML for the input field.
      def checkbox_tag(name, value = "1", **)
        input_field_tag(name, value, **, type: CHECKBOX)
      end
      alias check_box_tag checkbox_tag

      # Render a `input[type=color]` tag.
      #
      # @param name [String, Symbol] The name of the field.
      # @param value [String] The value of the field.
      # @return [SafeBuffer] The HTML for the input field.
      def color_field_tag(name, value = nil, **)
        input_field_tag(name, value, **, type: COLOR)
      end

      # Render a `input[type=date]` tag.
      #
      # @param name [String, Symbol] The name of the field.
      # @param value [String] The value of the field.
      # @return [SafeBuffer] The HTML for the input field.
      def date_field_tag(name, value = Date.today.iso8601, **)
        value = value.strftime(YEAR_MONTH_DAY) if value.respond_to?(:strftime)
        input_field_tag(name, value, **, type: DATE)
      end

      # Render a `input[type=datetime-local]` tag.
      #
      # @param name [String, Symbol] The name of the field.
      # @param value [String] The value of the field.
      # @return [SafeBuffer] The HTML for the input field.
      def datetime_field_tag(name, value = Time.now.iso8601, **)
        value = value.iso8601 if value.respond_to?(:iso8601)
        input_field_tag(name, value, **, type: DATETIME)
      end

      # Render a `input[type=file]` tag.
      #
      # @param name [String, Symbol] The name of the field.
      # @param value [String] The value of the field.
      # @return [SafeBuffer] The HTML for the input field.
      def file_field_tag(name, value = nil, **)
        input_field_tag(name, value, **, type: FILE)
      end

      # Render a `input[type=email]` field.
      # @param name [String, Symbol] The name of the field.
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
        # Capture the content before doing anything else. This is required
        # because we need to compute the `multipart` attribute if you're using
        # a file input.
        content = capture(&) if block_given?
        has_input_file = content.to_s.match?(INPUT_FILE_RE)

        attrs[:enctype] = MULTIPART if multipart || has_input_file
        buffer = SafeBuffer.new
        buffer << tag(:form, action:, method:, **attrs, open: true)

        if authenticity_token && method != :get
          buffer << input_field_tag(
            Controller.csrf_param_name,
            authenticity_token,
            type: :hidden,
            id: false
          )
        end

        buffer << content
        buffer << SafeBuffer.new(FORM_END)
        buffer
      end

      # Render a `input[type=hidden]` field.
      # @param name [String, Symbol] The name of the field.
      # @param value [String] The value of the field.
      # @param attrs [Hash{Symbol => Object}] The input attributes.
      # @return [SafeBuffer] The HTML for the input field.
      def hidden_field_tag(name, value = nil, **attrs)
        attrs[:id] = false unless attrs.key?(:id)
        input_field_tag(name, value, **attrs, type: HIDDEN)
      end

      # Render a `label` tag.
      # @param name [String, Symbol] The name of the field.
      # @param text [Object, nil] The label text.
      # @param attrs [Hash{Symbol => Object}] The label attributes.
      # @return [SafeBuffer] The HTML for the label.
      def label_tag(name, text = nil, **attrs, &)
        name = name.to_s

        attrs[:for] ||= normalize_id(name)
        text ||= (name[/\[([a-z_]+)\]/, 1] || name).humanize
        content_tag(:label, text, **attrs, &)
      end

      # Render a `input[type=month]` field.
      # @param name [String, Symbol] The name of the field.
      # @param value [String] The value of the field.
      # @return [SafeBuffer] The HTML for the input field.
      def month_field_tag(name, value = Date.today, **)
        value = value.strftime(YEAR_MONTH) if value.respond_to?(:strftime)
        input_field_tag(name, value, **, type: MONTH)
      end

      # Render a `input[type=number]` field.
      # @param name [String, Symbol] The name of the field.
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
      # @param name [String, Symbol] The name of the field.
      # @param value [String] The value of the field.
      # @param attrs [Hash{Symbol => Object}] The input attributes.
      # @return [SafeBuffer] The HTML for the input field.
      #
      # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete#new-password
      # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete#current-password
      # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete#one-time-code
      #
      # @example Using the `autocomplete` attribute
      #   password_field_tag :password, autocomplete: :current_password
      #   password_field_tag :password, autocomplete: :new_password
      #   password_field_tag :password, autocomplete: :one_time_code
      def password_field_tag(name, value = nil, **attrs)
        attrs[:autocomplete] ||= PASSWORD

        input_field_tag(name, value, **attrs, type: PASSWORD)
      end

      # Render a `input[type=tel]` field.
      # @param name [String, Symbol] The name of the field.
      # @param value [String] The value of the field.
      # @param attrs [Hash{Symbol => Object}] The input attributes.
      # @return [SafeBuffer] The HTML for the input field.
      #
      # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete#tel
      #
      # @example Using the `autocomplete` attribute
      #   phone_field_tag :phone #=> defaults to `autocomplete=tel`
      #   phone_field_tag :country_code, autocomplete: :tel_country_code
      #   phone_field_tag :phone, autocomplete: :tel_national
      #   phone_field_tag :area_code, autocomplete: :tel_area_code
      #   phone_field_tag :local_code, autocomplete: :tel_local
      #   phone_field_tag :ext, autocomplete: :tel_extension
      def phone_field_tag(name, value = nil, **attrs)
        attrs[:autocomplete] ||= TEL
        attrs[:inputmode] ||= TEL

        input_field_tag(name, value, **attrs, type: TEL)
      end

      # Render a `input[type=radio]` field.
      # @param name [String, Symbol] The name of the field.
      # @param value [String] The value of the field.
      # @param attrs [Hash{Symbol => Object}] The input attributes.
      # @return [SafeBuffer] The HTML for the input field.
      def radio_button_tag(name, value, **attrs)
        attrs[:id] ||= "#{normalize_id(name)}_#{normalize_id(value)}"

        input_field_tag(name, value, **attrs, type: RADIO)
      end
      alias radio_field_tag radio_button_tag

      # Render a `input[type=range]` field.
      # @param name [String, Symbol] The name of the field.
      # @param value [String] The value of the field.
      # @param attrs [Hash{Symbol => Object}] The input attributes.
      # @option attrs [Range] :in The range of numbers.
      # @option attrs [Integer] :min The minimum value.
      # @option attrs [Integer] :max The maximum value.
      # @return [SafeBuffer] The HTML for the input field.
      def range_field_tag(name, value = nil, **attrs)
        within = attrs.delete(:in)
        attrs[:min], attrs[:max] = within.minmax if within.is_a?(Range)

        input_field_tag(name, value, **attrs, type: RANGE)
      end

      # Render a `input[type=search]` field.
      # @param name [String, Symbol] The name of the field.
      # @param value [String] The value of the field.
      # @return [SafeBuffer] The HTML for the input field.
      def search_field_tag(name, value = nil, **)
        input_field_tag(name, value, **, type: SEARCH)
      end

      # Render a `select` field.
      # @param name [String, Symbol] The name of the field.
      # @param include_blank [Boolean] Whether to include a blank option.
      # @param options [Array<Object>, Hash{Object => Array<Object>}]
      # @param selected [Array<Object>, nil] Which options should be marked as
      #                                      selected.
      # @param attrs [Hash{Symbol => Object}] The select attributes.
      # @param disabled_options [Array<Object>] The options that must be
      #                                         disabled. To disable the
      #                                         `select`, use `disabled: true`
      #                                         instead.
      # @return [SafeBuffer] The HTML for the input field.
      def select_tag(
        name,
        options = [],
        include_blank: true,
        selected: nil,
        disabled_options: [],
        **attrs
      )
        name = name.to_s
        attrs[:id] ||= normalize_id(name) unless name.blank?

        options = case options
                  when String
                    SafeBuffer.new(options)
                  when SafeBuffer
                    options
                  when Hash
                    options_from_hash_for_select(
                      options,
                      selected,
                      disabled_options:
                    )
                  else
                    options_from_array_for_select(
                      options,
                      selected,
                      disabled_options:
                    )
                  end

        buffer = SafeBuffer.new
        buffer << tag(:option, "", value: "") if include_blank
        buffer << options

        content_tag(:select, buffer, name:, **attrs)
      end

      # Render a hash as a list of `<optgroup>` elements.
      # @param options [Hash{Object => Array<Object>}] The options to render.
      # @param selected [Array<Object>] Which options should be marked as
      #                                 selected.
      # @param disabled_options [Array<Object>] The options that must be
      #                                         disabled.
      #
      # @see #select_tag
      # @note You don't need to use this method directly; instead, you can pass
      #       a hash to the `options` parameter of {#select_tag}.
      #
      # @example
      #   options = options_from_hash_for_select(
      #     "Dynamic" => [[1, "Ruby"], [2, "Python"]],
      #     "Static" => [[3, "Rust"]]
      #   )
      #
      #   select_tag(:languages, options)
      def options_from_hash_for_select(options, selected, disabled_options:)
        buffer = SafeBuffer.new

        options.each do |label, group_options|
          buffer << content_tag(:optgroup, label: label) do
            options_from_array_for_select(
              group_options,
              selected,
              disabled_options:
            )
          end
        end

        buffer
      end

      # Render a hash as a list of `<option>` elements.
      # @param options [Array<Object>] The options to render.
      # @param selected [Array<Object>] Which options should be marked as
      #                                 selected.
      # @param disabled_options [Array<Object>] The options that must be
      #                                         disabled.
      #
      # @see #select_tag
      # @note You don't need to use this method directly; instead, you can pass
      #       an array to the `options` parameter of {#select_tag}.
      #
      # @example
      #   options = options_from_array_for_select([[1, "Ruby"], [2, "Python"]])
      #
      #   select_tag(:languages, options)
      def options_from_array_for_select(options, selected, disabled_options:)
        selected = Array(selected).map(&:to_s)
        disabled_options = Array(disabled_options).map(&:to_s)
        buffer = SafeBuffer.new

        options.each do |(value, label)|
          value = value.to_s

          buffer << tag(
            :option,
            label,
            value:,
            selected: selected.include?(value),
            disabled: disabled_options.include?(value)
          )
        end

        buffer
      end

      # Render a `textarea` field.
      # @param name [String, Symbol] The name of the field.
      # @param value [String] The value of the field.
      # @param escape [Boolean] Whether to escape the value.
      # @return [SafeBuffer] The HTML for the textarea field.
      def textarea_tag(name, value = nil, escape: true, **)
        value = SafeBuffer.new(value) unless escape
        name = name.to_s
        id = normalize_id(name) unless name.blank?

        content_tag(:textarea, value, name:, id:, **)
      end
      alias text_area_tag textarea_tag

      # Render a `input[type=text]` field.
      # @param name [String, Symbol] The name of the field.
      # @param value [String] The value of the field.
      # @return [SafeBuffer] The HTML for the input field.
      def text_field_tag(name, value = nil, **)
        input_field_tag(name, value, **, type: TEXT)
      end

      # Render a `input[type=time]` field.
      # @param name [String, Symbol] The name of the field.
      # @param value [String] The value of the field.
      # @param include_seconds [Boolean] Whether to include seconds.
      # @return [SafeBuffer] The HTML for the input field.
      # @param [Hash{Symbol => Object}] attrs
      def time_field_tag(name, value = nil, include_seconds: false, **attrs)
        if value.respond_to?(:strftime)
          format = include_seconds ? TIME_WITH_SECONDS : TIME_WITHOUT_SECONDS
          value = value.strftime(format)
        elsif value
          parts = value.to_s
                       .split(COLON)
                       .push(DOUBLE_ZERO, DOUBLE_ZERO, DOUBLE_ZERO)
                       .take(include_seconds ? 3 : 2)
          value = parts.join(COLON)
        end

        attrs[:step] ||= 1 if include_seconds

        input_field_tag(name, value, **attrs, type: TIME)
      end

      # Render a `input[type=url]` field.
      # @param name [String, Symbol] The name of the field.
      # @param value [String] The value of the field.
      # @param attrs [Hash{Symbol => Object}] The input attributes.
      # @return [SafeBuffer] The HTML for the input field.
      def url_field_tag(name, value = nil, **attrs)
        attrs[:autocomplete] ||= URL
        attrs[:spellcheck] ||= false
        attrs[:autocapitalize] ||= OFF
        attrs[:pattern] ||= URL_PATTERN
        input_field_tag(name, value, **attrs, type: URL)
      end

      # Render a `input` field.
      # @param name [String, Symbol] The name of the field.
      # @param value [String] The value of the field.
      # @param type [String] The type of the field.
      # @param attrs [Hash{Symbol => Object}] The input attributes.
      # @return [SafeBuffer] The HTML for the input field.
      def input_field_tag(name, value = nil, type: TEXT, **attrs)
        name = name.to_s
        id = normalize_id(name) if !attrs.key?(:id) && name.present?

        if attrs[:autocomplete]
          attrs[:autocomplete] = attrs[:autocomplete].to_s.tr(UNDERSCORE, DASH)
        end

        tag(:input, name:, value:, type:, id:, **attrs)
      end

      # @private
      def normalize_id(name)
        name.to_s.delete(CLOSE_SQUARE_BRACKET).tr(ID_CLEANER, UNDERSCORE)
      end

      # Render a form for a given object.
      # @param object [Object] The object to render the form for.
      # @param action [String] The action attribute of the form.
      # @param as [String] The name of the object.
      # @return [SafeBuffer] The HTML for the form.
      #
      # @example
      #   <%= form_for(user, action: "/users") do |f| %>
      #     <p>
      #       <%= f.label :name %>
      #       <%= f.text_field :name %>
      #     </p>
      #
      #     <p>
      #       <%= f.label :email %>
      #       <%= f.email_field :email %>
      #     </p>
      #
      #     <p><%= f.submit %></p>
      #   <% end %>
      def form_for(object, action:, as: :form, **, &)
        authenticity_token = request.env[ZEE_CSRF_TOKEN]

        form = FormBuilder.new(object:, context: self, object_name: as, **)
        form_tag(action:, authenticity_token:, **) { instance_exec(form, &) }
      end
    end
  end
end
