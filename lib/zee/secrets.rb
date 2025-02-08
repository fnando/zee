# frozen_string_literal: true

module Zee
  class Secrets
    # Initialize the secrets object.
    # @param credentials_file [String] The path to the encrypted file.
    # @param key [String] The key to decrypt the credentials file.
    def initialize(credentials_file:, key:)
      @credentials_file = credentials_file
      @key = key
    end

    # Access secrets using hash-like syntax.
    # @param key [String, Symbol]
    # @return [Object]
    def [](key)
      store[key.to_sym]
    end

    def method_missing(name, *, **, &)
      return super unless store.key?(name)

      store[name]
    end

    def respond_to_missing?(name, *)
      store.key?(name) || super
    end

    private def store
      @store ||= begin
        encrypted = EncryptedFile.new(path: @credentials_file, key: @key)
        YAML.safe_load(encrypted.read, symbolize_names: true)
      end
    end
  end
end
