# frozen_string_literal: true

module Zee
  class Secrets
    # Initialize the secrets object.
    # @param secrets_file [String] The path to the encrypted file.
    # @param keyring [Keyring] The key to decrypt the secrets file.
    def initialize(secrets_file:, keyring:)
      @secrets_file = secrets_file
      @keyring = keyring
    end

    # Access secrets using hash-like syntax.
    # @param key [String, Symbol]
    # @return [Object]
    #
    # @example
    #   secrets[:database_url]
    def [](key)
      store[key.to_sym]
    end

    # Access secrets using method-like syntax.
    # @example
    #   secrets.database_url
    def method_missing(name, *, **, &)
      return super unless store.key?(name)

      store[name]
    end

    # @api private
    def respond_to_missing?(name, *)
      store.key?(name) || super
    end

    # @api private
    def to_s
      "#<Zee::Secrets secrets_file=#{@secrets_file}>"
    end
    alias inspect to_s

    # @api private
    private def store
      @store ||= begin
        encrypted = EncryptedFile.new(path: @secrets_file, keyring: @keyring)
        YAML.safe_load(encrypted.read, symbolize_names: true)
      end
    end
  end
end
