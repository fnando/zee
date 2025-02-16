# frozen_string_literal: true

module Zee
  class Encryptor
    def initialize(cipher:, key:)
      @cipher = cipher
      @key = key
    end
  end
end
