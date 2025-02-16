# frozen_string_literal: true

module Zee
  class Keyring
    # Raised when a key is not found in the keyring.
    UnknownKey = Class.new(StandardError)

    # Raised when a key has an invalid size.
    InvalidSecret = Class.new(StandardError)

    # Raised when trying to encrypt/decrypt with an empty keyring.
    EmptyKeyring = Class.new(StandardError)

    # Raised when the HMAC verification fails.
    InvalidAuthentication = Class.new(StandardError)

    # Raised when the digest salt is missing.
    MissingDigestSalt = Class.new(StandardError)

    # Initialize a new keyring.
    # @param keyring [Hash{Integer => String}] the keyring.
    # @param [String, nil] digest_salt
    # @param [Object] encryptor
    # @return [Keyring]
    def initialize(
      keyring,
      digest_salt: nil,
      encryptor: Encryptor::AES::AES128CBC
    )
      if digest_salt.nil?
        raise MissingDigestSalt,
              "Please provide :digest_salt; you can disable this error by " \
              "explicitly passing an empty string."
      end

      @encryptor = encryptor
      @digest_salt = digest_salt
      @keyring = keyring.map do |id, value|
        Key.new(id:, key: value, size: @encryptor.key_size)
      end
    end

    # Returns the current key.
    # @return [Key, nil]
    def current_key
      @keyring.max_by(&:id)
    end

    # Returns the key with the given id.
    # @param id [Integer]
    # @return [Key]
    # @raise [EmptyKeyring] if the keyring is empty.
    # @raise [UnknownKey] if the key is not found.
    def [](id)
      raise EmptyKeyring, "keyring doesn't have any keys" if @keyring.empty?

      key = @keyring.find {|k| k.id == id.to_i }
      return key if key

      raise UnknownKey, "key=#{id} is not available on keyring"
    end

    # Adds a new key to the keyring.
    # @param id [Integer]
    # @param key [String]
    # @return [Key]
    def []=(id, key)
      @keyring << Key.new(id:, key:, size: @encryptor.key_size)
    end

    # Removes all keys from the keyring.
    def clear
      @keyring.clear
    end

    # Returns the number of keys in the keyring.
    # @return [Integer]
    def size
      @keyring.size
    end

    # Encrypts a message using the current key.
    # @param message [String] the message to encrypt.
    # @param keyring_id [Integer, nil] the keyring id to use.
    # @return [Array(String, Integer, String)] the encrypted message, keyring
    #                                          id, and digest.
    def encrypt(message, keyring_id = nil)
      keyring_id ||= current_key&.id
      key = self[keyring_id]

      [
        @encryptor.encrypt(key, message),
        keyring_id,
        digest(message)
      ]
    end

    # Decrypts a message using the given keyring id.
    # @param message [String] the message to decrypt.
    # @param keyring_id [Integer] the keyring id to use.
    # @return [String] the decrypted message.
    def decrypt(message, keyring_id)
      key = self[keyring_id]
      @encryptor.decrypt(key, message)
    end

    # Returns the SHA1 digest of a message.
    # @param message [String]
    # @return [String]
    def digest(message)
      Digest::SHA1.hexdigest("#{message}#{@digest_salt}")
    end
  end
end
