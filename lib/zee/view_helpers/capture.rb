# frozen_string_literal: true

module Zee
  module ViewHelpers
    module Capture
      # The output buffer is the buffer where the rendered view is stored.
      # You can use it, for instance, when you're creating helpers that need to
      # generate content.
      #
      # @example
      #   This is what your ruby helper could look like:
      #
      #   ```ruby
      #   def h1(title)
      #     buffer = SafeBuffer.new.concat("<h1>")
      #     buffer << title
      #     buffer << SafeBuffer.new("</h1>")
      #     @output_buffer << buffer
      #   end
      #   ```
      #
      #   This helper can be used in a view like the following.
      #
      #   ```erb
      #   <% h1("Hello") %>
      #   ```
      #
      #   > [!NOTE]
      #   > Notice where not using `<%=`. This is because the helper is
      #   > appending the content to the output buffer directly.
      def output_buffer
        @output_buffer
      end

      # Capture the output of the block.
      # The output is returned as it is, with no escaping. Make sure to escape
      # the output if necessary.
      #
      # @return [String] The output of the block.
      #
      # @example
      #   This is what your ruby helper could look like:
      #
      #   ```ruby
      #   def section(&)
      #     buffer = SafeBuffer.new.concat("<section>")
      #     buffer << capture(&)
      #     buffer << "</section>"
      #   end
      #   ```
      #
      #   This helper can be used in a view like the following.
      #
      #   ```erb
      #   <%= section do %>
      #     <h1>This is a section</h1>
      #   <% end %>
      #   ```
      def capture(&)
        output_buffer.capture(&)
      end
    end
  end
end
