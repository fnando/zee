# frozen_string_literal: true

module Zee
  class Headers
    def initialize
      @store = {}
    end

    # Get the value of a header.
    # @param name [String] the name of the header.
    # @return [String] the value of the header.
    def [](name)
      @store[transform_key(name)]
    end

    # Set the value of a header.
    # @param name [String] the name of the header.
    # @param value [String] the value of the header.
    def []=(name, value)
      @store[transform_key(name)] = value
    end

    # Get a hash representation of all headers.
    # @return [Hash]
    def to_h
      @store
    end

    private def transform_key(name)
      name.to_s.tr(UNDERSCORE, DASH).downcase
    end
  end
end
