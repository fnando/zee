# frozen_string_literal: true

module Zee
  class Keyring
    # @api private
    class Key
      attr_reader :id, :signing_key, :encryption_key

      def initialize(id:, key:, size:)
        @id = Integer(id.to_s)
        @size = size
        @encryption_key, @signing_key = parse_key(key)
      end

      # @api private
      def to_s
        "#<#{self.class.name} id=#{id.inspect}>"
      end
      alias inspect to_s

      # @api private
      private def parse_key(key)
        expected_size = @size * 2
        secret = decode_key(key, expected_size)

        unless secret.bytesize == expected_size
          raise InvalidSecret,
                "Secret must be #{expected_size} bytes; " \
                "got #{key.bytesize}"
        end

        signing_key = secret[0...@size]
        encryption_key = secret[@size..-1]

        [encryption_key, signing_key]
      end

      # @api private
      private def decode_key(key, size)
        if key.bytesize == size
          key
        else
          begin
            Base64.strict_decode64(key)
          rescue ArgumentError
            Base64.decode64(key)
          end
        end
      end
    end
  end
end
