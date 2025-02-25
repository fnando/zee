# frozen_string_literal: true

module Zee
  module ViewHelpers
    module Capture
      # The output buffer is the buffer where the rendered view is stored.
      # You can use it, for instance, when you're creating helpers that need to
      # generate content.
      #
      # @example
      #   # A helper.
      #     def h1(title)
      #       buffer = SafeBuffer.new.concat("<h1>")
      #       buffer << title
      #       buffer << SafeBuffer.new("</h1>")
      #       @output_buffer << buffer.to_s
      #     end
      #
      #   # Your view.
      #   # Notice where not using `<%=` here.
      #   <% h1("Hello") %>
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
      #   # a helper
      #   def section(&)
      #     buffer = SafeBuffer.new.concat("<section>")
      #     buffer << capture(&)
      #     buffer << "</section>"
      #   end
      #
      #   # your view
      #   <%=
      def capture(&)
        output_buffer.capture(&)
      end
    end
  end
end
