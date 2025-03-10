# frozen_string_literal: true

module Zee
  module ViewHelpers
    module HTML
      using Core::String
      include OutputSafety
      include Capture

      # @api private
      OPEN_TAGS = %w[
        area base br col command embed hr img input keygen link meta param
        source track wbr
      ].freeze

      # @api private
      BOOLEAN_ATTRS = %w[
        allowfullscreen async autofocus autoplay checked controls default defer
        disabled formnovalidate hidden ismap itemscope loop multiple muted
        nomodule novalidate open playsinline readonly required reversed selected
        truespeed
      ].freeze

      # @api private
      KEEP_BLANK_ATTRS = %w[value alt].freeze

      # Returns an HTML tag with the specified content.
      #
      # @param name [String] the name of the tag.
      # @param content [String, nil] the content to put inside the tag.
      # @param attrs [Hash] the attributes to add to the tag.
      # @return [Zee::SafeBuffer]
      #
      # @example Using a string
      #   ```erb
      #   <%= tag(:div, "hello!") %>
      #   ```
      #
      # @example Passing attributes
      #   ```erb
      #   <%= tag(:div, "hello!", id: "header") %>
      #   ```
      #
      # @example Open tags
      #   ```erb
      #   <%= tag(:br, id: "header") %>
      #   ```
      def tag(name, content = nil, **attrs)
        open_tag = OPEN_TAGS.include?(name.to_s) || attrs.delete(:open)
        attrs = html_attrs(attrs)
        buffer = SafeBuffer.new
        buffer << SafeBuffer.new("<#{name}#{attrs}>")

        unless open_tag
          buffer << content
          buffer << SafeBuffer.new("</#{name}>")
        end

        buffer
      end

      # Returns an HTML tag with the specified content.
      #
      # @param name [String] the name of the tag.
      # @param content [String, nil] the content to put inside the tag.
      # @param attrs [Hash] the attributes to add to the tag.
      # @yieldreturn [String] the content to put inside the tag.
      # @return [Zee::SafeBuffer]
      #
      # @example Using a block
      #   ```erb
      #   <%= content_tag(:div) do %>
      #     Hello, World!
      #   <% end %>
      #   ```
      #
      # @example Using a string
      #   ```erb
      #   <%= content_tag(:div, "hello!") %>
      #   ```
      #
      # @example Passing attributes
      #   ```erb
      #   <%= content_tag(:div, "hello!", id: "header") %>
      #   ```
      def content_tag(name, content = nil, **attrs, &)
        content = capture(&) if block_given?
        tag(name, content, **attrs)
      end

      # Returns a JavaScript tag with the content inside.
      # If the middleware {#Zee::Middleware::ContentSecurityPolicy} is in use,
      # the tag will have a nonce attribute.
      # @param content [String, nil] the content to put inside the tag.
      # @yieldreturn [String] the content to put inside the tag.
      # @return [Zee::SafeBuffer]
      #
      # @example Using a block
      #   ```erb
      #   <%= javascript_tag do %>
      #     console.log("Hello, World!");
      #   <% end %>
      #   ```
      #
      # @example Passing a string
      #   ```erb
      #   <%= javascript_tag(%[console.log("Hello, World!");])
      #   ```
      def javascript_tag(content = nil, &)
        content = if block_given?
                    capture(&).raw
                  else
                    SafeBuffer.new(content)
                  end
        nonce = request.env[ZEE_CSP_NONCE]
        attrs = {nonce:} if nonce

        content_tag :script, content, **attrs
      end

      # Returns a JavaScript tag with the content inside.
      # If the middleware {#Zee::Middleware::ContentSecurityPolicy} is in use,
      # the tag will have a nonce attribute.
      # @param content [String, nil] the content to put inside the tag.
      # @yieldreturn [String] the content to put inside the tag.
      # @return [Zee::SafeBuffer]
      #
      # @example Using a block
      #   ```erb
      #   <%= style_tag do %>
      #     body { color: red; }
      #   <% end %>
      #   ```
      #
      # @example Passing a string
      #   ```erb
      #   <%= style_tag("body { color: red; }")
      #   ```
      def style_tag(content = nil, &)
        content = if block_given?
                    capture(&)&.raw
                  else
                    SafeBuffer.new(content)
                  end
        nonce = request.env[ZEE_CSP_NONCE]
        attrs = {nonce:} if nonce

        content_tag :style, content, **attrs
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
        classes = args.flatten.each_with_object([]) do |val, buffer|
          if val.is_a?(Hash)
            val.each {|k, v| buffer << k if v && v.to_s != EMPTY_STRING }
          elsif val && val.to_s != EMPTY_STRING
            buffer << val
          end
        end

        classes = kwargs.each_with_object(classes) do |(k, v), buffer|
          buffer << k if v && v.to_s != EMPTY_STRING
        end

        escape_html(classes.map(&:to_s).uniq.join(SPACE))
      end

      # @api private
      # Build the HTML attributes.
      # @param attrs [Hash{Symbol => Object}]
      # @return [String]
      def html_attrs(attrs)
        attrs[:class] = class_names(attrs[:class]) if attrs[:class]
        attrs = attrs.merge(ns_attrs(:data, attrs.delete(:data)))
        attrs = attrs.merge(
          ns_attrs(:aria, attrs.delete(:aria), stringify_value: true)
        )
        attrs.map {|k, v| build_attr(k, v) }.join
      end

      # @api private
      # Build namespaced attributes. Any key with an underscore will be
      # converted to a dash.
      # @param attrs [Hash{Symbol => Object}]
      # @param stringify_value [Boolean] whether to convert the value to a
      #                                  string.
      # @return [Hash{String => Object}]
      private def ns_attrs(namespace, attrs, stringify_value: false)
        Hash(attrs).each_with_object({}) do |(k, v), buffer|
          v = v.to_s if stringify_value
          buffer["#{namespace}-#{k.to_s.tr(UNDERSCORE, DASH)}"] = v
        end
      end

      # @api private
      private def build_attr(name, value)
        name = name.to_s

        if BOOLEAN_ATTRS.include?(name)
          if value
            " #{name}"
          else
            EMPTY_STRING
          end
        elsif value
          value = value.to_s
          ignore = value.empty? && !KEEP_BLANK_ATTRS.include?(name)
          return EMPTY_STRING if ignore

          %[ #{escape_html(name)}="#{escape_html(value)}"]
        end
      end
    end
  end
end
