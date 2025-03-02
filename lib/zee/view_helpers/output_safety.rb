# frozen_string_literal: true

module Zee
  module ViewHelpers
    module OutputSafety
      # Output the input as a raw string, meaning no escape will be performed.
      # @param input [Object] the input to output.
      # @return [Zee::SafeBuffer]
      # @example
      #   ```erb
      #   <%= raw("<script>alert(1)</script>") %>
      #   ```
      def raw(input)
        if input.is_a?(Zee::SafeBuffer)
          input.raw
        else
          Zee::SafeBuffer.new(input)
        end
      end

      # Escape the JSON string.
      # @param string [Object] the input to escape.
      # @return [String]
      # @example
      #   ```erb
      #   <%= escape_json("<script>alert(1)</script>".to_json) %>
      #   ```
      def escape_json(string)
        Zee::SafeBuffer.new(string).to_json
      end

      # Escape the HTML string.
      # @param input [Object] the input to escape.
      # @return [String]
      # @example
      #   ```erb
      #   <%= escape_html("<script>alert(1)</script>") %>
      #   ```
      def escape_html(input)
        Zee::SafeBuffer.new.concat(input).to_s
      end
    end
  end
end
