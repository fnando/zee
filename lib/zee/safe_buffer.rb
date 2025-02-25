# frozen_string_literal: true

module Zee
  class SafeBuffer
    JSON_ESCAPE = {
      "&" => '\u0026',
      ">" => '\u003e',
      "<" => '\u003c',
      "\u2028" => '\u2028',
      "\u2029" => '\u2029'
    }.freeze
    JSON_ESCAPE_REGEXP = /[\u2028\u2029&><]/u

    # Escape HTML.
    # @param input [Object] the input to escape.
    # @return [String]
    def self.escape_html(input)
      if input.is_a?(self)
        input.to_s
      else
        new.concat(input).to_s
      end
    end

    # Escape JSON.
    # @param input [Object] the input to escape.
    # @return [String]
    def self.escape_json(input)
      if input.is_a?(self)
        input.to_json
      else
        new.concat(input).to_json
      end
    end

    # Create a new Zee::SafeBuffer instance.
    # You can pass a string to be used as the initial buffer.
    # This is useful when you want to append to an existing string.
    # The initial buffer is always considered safe. If you're unsure if the
    # input is safe, use something like `Zee::SafeBuffer.new.concat(input)`
    # instead.
    #
    # @param safe_input [Object] the initial buffer.
    # @return [Zee::SafeBuffer]
    def initialize(safe_input = "")
      @buffer = [safe_input]
    end

    # Append to the buffer.
    # This method is chainable.
    # @param input [Object] the input to append.
    # @return [Zee::SafeBuffer] self
    def <<(input)
      @buffer << input
      self
    end
    alias + <<

    # Add `other` to the buffer and returns `self`.
    # This method is chainable.
    # @param other [Object] the buffer to concatenate.
    # @return [Zee::SafeBuffer] self
    def concat(other)
      copy = dup
      copy << other
      copy
    end

    def eql?(other)
      to_s == other.to_s
    end
    alias == eql?

    # Return the buffer as a string.
    # @return [String]
    def to_s
      [@buffer[0]].concat(@buffer[1..-1].map { escape(_1) }).join
    end
    alias inspect to_s

    # Convert existing buffer into a safe one.
    # @return [Zee::SafeBuffer]
    def raw
      self.class.new(@buffer.join)
    end

    # Convert the buffer to JSON.
    # @return [String]
    def to_json(*)
      raw.to_s.gsub(JSON_ESCAPE_REGEXP, JSON_ESCAPE)
    end

    # @private
    private def escape(item)
      if item.is_a?(self.class)
        item.to_s
      else
        CGI.escape_html(item.to_s)
      end
    end

    # @private
    class Erubi < ::Erubi::CaptureBlockEngine::Buffer
      def |(other)
        concat(SafeBuffer.escape_html(other))
      end
    end
  end
end
