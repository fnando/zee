# frozen_string_literal: true

module Zee
  module ViewHelpers
    module HTML
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
        content = @output_buffer.capture(&) if block_given?
        nonce = request.env[ZEE_CSP_NONCE]

        buffer = if nonce
                   SafeBuffer.new(%[<script nonce="#{nonce}">])
                 else
                   SafeBuffer.new("<script>")
                 end
        buffer << SafeBuffer.new(content)
        buffer << SafeBuffer.new("</script>")
        buffer
      end
    end
  end
end
