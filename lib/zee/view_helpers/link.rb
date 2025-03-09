# frozen_string_literal: true

module Zee
  module ViewHelpers
    module Link
      # @api private
      EXTERNAL_REL = "noreferrer noopener nofollow external"

      # @api private
      TARGET_BLANK = "_blank"

      # Render a `<a>` tag with the specified content.
      #
      # @param text [String, nil] the text to display in the link. If a block is
      #                           given, this is ignored.
      # @param url [String, nil] the URL to link to.
      # @param blank [Boolean, nil] whether to open the link in a new tab (by
      #                             adding `target="_blank"` to the link.
      # @param external [Boolean] When `true`, the link will be rendered
      #                           with `rel="noreferrer noopener nofollow"`.
      # @param attrs [Hash{Symbol => Object}] Other link attributes.
      # @yieldreturn [String] the content to put inside the tag.
      # @return [Zee::SafeBuffer]
      #
      # @example Using a block
      #   ```erb
      #   <%= link_to root_path do %>
      #     <%= content_tag :span, "Home", class: :home_icon %>
      #   <% end %>
      #   ```
      #
      # @example Using a string
      #   ```erb
      #   <%= link_to "Home", root_path %>
      #   ```
      #
      # @example Opening in a new tab
      #    ```erb
      #    <%= link_to "Home", root_path, blank: true %>
      #    ```
      #
      # @example Linking to external urls.
      #   ```erb
      #   <%= link_to "Blog", "https://www.example.com", external: true %>
      #   ```
      def link_to(text = nil, url = nil, blank: nil, external: nil, **attrs, &)
        url = text if block_given?
        attrs[:target] = TARGET_BLANK if blank
        attrs[:rel] = EXTERNAL_REL if external
        content_tag(:a, text, href: url, **attrs, &)
      end
    end
  end
end
