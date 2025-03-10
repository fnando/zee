# frozen_string_literal: true

module Zee
  module ViewHelpers
    module MetaTag
      # @api private
      META = "meta"

      # @api private
      CSP_NONCE = "csp-nonce"

      # @api private
      CSRF_PARAM = "csrf-param"

      # @api private
      CSRF_TOKEN = "csrf-token"

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

      # Render the CSRF meta tags.
      # This can be used so JavaScript can send the CSRF token to the backend.
      #
      # @return [Zee::SafeBuffer]
      #
      # @example
      #   ```erb
      #   <%= csrf_meta_tag %>
      #   ```
      def csrf_meta_tag
        authenticity_token = controller.send(:authenticity_token)

        tag(META, name: CSRF_PARAM, content: Zee::Controller.csrf_param_name) +
          tag(META, name: CSRF_TOKEN, content: authenticity_token)
      end
      alias csrf_meta_tags csrf_meta_tag
    end
  end
end
