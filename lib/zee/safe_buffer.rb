# frozen_string_literal: true

module Zee
  class SafeBuffer
    # @api private
    JSON_ESCAPE = {
      "&" => '\u0026',
      ">" => '\u003e',
      "<" => '\u003c',
      "\u2028" => '\u2028',
      "\u2029" => '\u2029'
    }.freeze

    # @api private
    JSON_ESCAPE_REGEXP = /[\u2028\u2029&><]/u

    # @api private
    def self.safe_buffer_instance?(item)
      item.class.ancestors.include?(SafeBuffer)
    end

    # Escape HTML.
    # @param input [Object] the input to escape.
    # @return [String]
    def self.escape_html(input)
      if safe_buffer_instance?(input)
        input.to_s
      else
        new.concat(input).to_s
      end
    end

    # Escape JSON.
    # @param input [Object] the input to escape.
    # @return [String]
    def self.escape_json(input)
      input.to_json.gsub(JSON_ESCAPE_REGEXP, JSON_ESCAPE)
    end

    # Create a new Zee::SafeBuffer instance.
    # You can pass a string to be used as the initial buffer.
    # This is useful when you want to append to an existing string.
    # **The initial buffer is always considered safe.** If you're unsure if the
    # input is safe, use something like `Zee::SafeBuffer.new.concat(input)`
    # instead.
    #
    # @param safe_input [Object] the initial buffer.
    # @return [Zee::SafeBuffer]
    def initialize(safe_input = EMPTY_STRING)
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
      [@buffer[0]].concat(Array(@buffer[1..-1]).map { escape(_1) }).join
    end

    # @api private
    def inspect
      to_s.inspect
    end

    # Convert existing buffer into a safe one.
    # @return [Zee::SafeBuffer]
    def raw
      self.class.new(@buffer.join)
    end

    # @api private
    private def escape(item)
      if self.class.safe_buffer_instance?(item)
        item.to_s
      else
        CGI.escape_html(item.to_s)
      end
    end

    # @api private
    class Erubi < SafeBuffer
      def initialize(safe_buffer = EMPTY_STRING, root: false)
        super(safe_buffer)
        @root = root
      end

      def root?
        @root
      end

      def capture(*, &)
        prev = @buffer
        @buffer = []
        @buffer = self.class.new
        content = yield(*)
        add = !content.respond_to?(:root?) || !content.root?
        @buffer << content if add
        @buffer
      ensure
        @buffer = prev
      end

      def |(other)
        @buffer << other
        self
      end

      def <<(other)
        @buffer << SafeBuffer.new(other)
        self
      end
    end
  end
end
