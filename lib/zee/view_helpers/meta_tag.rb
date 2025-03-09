# frozen_string_literal: true

module Zee
  module ViewHelpers
    module MetaTag
      # @api private
      META = "meta"

      # @api private
      CSP_NONCE = "csp-nonce"

      # Render a `<meta>` tag with the CSP nonce.
      # This can be used if you need render `<script>` and `<style>` dynamically
      # from JavaScript.
      #
      # @return [Zee::SafeBuffer]
      #
      # @example
      #   ```erb
      #   <%= csp_meta_tag %>
      #   ```
      def csp_meta_tag
        content = request.env[ZEE_CSP_NONCE]
        tag(META, name: CSP_NONCE, content:)
      end
    end
  end
end
