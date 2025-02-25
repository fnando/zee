# frozen_string_literal: true

module Zee
  module ViewHelpers
    module HTML
      # Returns an HTML tag with the specified content.
      #
      # @param name [String] the name of the tag.
      # @param content [String, nil] the content to put inside the tag.
      # @param attrs [Hash] the attributes to add to the tag.
      # @yieldreturn [String] the content to put inside the tag.
      # @return [Zee::SafeBuffer]
      #
      # @example Using a block
      #   <%= content_tag(:div) do %>
      #     Hello, World!
      #   <% end %>
      #
      # @example Using a string
      #   <%= content_tag(:div, "hello!") %>
      #
      # @example Passing attributes
      #   <%= content_tag(:div, "hello!", id: "header") %>
      def content_tag(name, content = nil, **attrs, &)
        attrs = html_attrs(attrs)
        content = capture(&) if block_given?
        buffer = SafeBuffer.new
        buffer << SafeBuffer.new("<#{name}#{attrs}>")
        buffer << content
        buffer << SafeBuffer.new("</#{name}>")
        buffer
      end

      # Returns a JavaScript tag with the content inside.
      # If the middleware {#Zee::Middleware::ContentSecurityPolicy} is in use,
      # the tag will have a nonce attribute.
      # @param content [String, nil] the content to put inside the tag.
      # @yieldreturn [String] the content to put inside the tag.
      # @return [Zee::SafeBuffer]
      #
      # @example Using a block
      #   <%= javascript_tag do %>
      #     console.log("Hello, World!");
      #   <% end %>
      #
      # @example Passing a string
      #   <%= javascript_tag(%[console.log("Hello, World!");])
      def javascript_tag(content = nil, &)
        content = capture(&) if block_given?
        nonce = request.env[ZEE_CSP_NONCE]
        attrs = {nonce:} if nonce

        content_tag :script, SafeBuffer.new(content), **attrs
      end

      # Returns a JavaScript tag with the content inside.
      # If the middleware {#Zee::Middleware::ContentSecurityPolicy} is in use,
      # the tag will have a nonce attribute.
      # @param content [String, nil] the content to put inside the tag.
      # @yieldreturn [String] the content to put inside the tag.
      # @return [Zee::SafeBuffer]
      #
      # @example Using a block
      #   <%= style_tag do %>
      #     body { color: red; }
      #   <% end %>
      #
      # @example Passing a string
      #   <%= style_tag("body { color: red; }")
      def style_tag(content = nil, &)
        content = capture(&) if block_given?
        nonce = request.env[ZEE_CSP_NONCE]
        attrs = {nonce:} if nonce

        content_tag :style, SafeBuffer.new(content), **attrs
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

      # @private
      # Build the HTML attributes.
      # @param attrs [Hash{Symbol => Object}]
      # @return [String]
      def html_attrs(attrs)
        attrs[:class] = class_names(attrs[:class]) if attrs[:class]
        attrs = attrs.merge(data_attrs(attrs.delete(:data)))
        attrs.map {|k, v| %[ #{escape_html(k)}="#{escape_html(v)}"] }.join
      end

      # @private
      # Build the data attributes. Any key with an underscore will be converted
      # to a dash.
      # @param attrs [Hash{Symbol => Object}]
      # @return [Hash{String => Object}]
      private def data_attrs(attrs)
        Hash(attrs).each_with_object({}) do |(k, v), buffer|
          buffer["data-#{k.to_s.tr(UNDERSCORE, DASH)}"] = v
        end
      end
    end
  end
end
