# frozen_string_literal: true

module Zee
  class Headers
    def initialize
      @store = {}
    end

    def [](name)
      @store[transform_key(name)]
    end

    def []=(name, value)
      @store[transform_key(name)] = value
    end

    def to_h
      @store
    end

    private def transform_key(name)
      name.to_s.tr("_", "-").downcase
    end
  end
end
