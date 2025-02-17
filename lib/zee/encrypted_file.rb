# frozen_string_literal: true

require "base64"
require "openssl"

module Zee
  class EncryptedFile
    ValidationError = Class.new(StandardError)

    SEPARATOR = "--"

    # Where the encrypted file will be saved.
    # @return [String]
    attr_reader :path

    # The [Keyring] that will be used to encrypt and decrypt the file.
    # @param path [String]
    attr_reader :keyring

    # @param path [String]
    # @param keyring [Keyring]
    # @return [EncryptedFile]
    def initialize(path:, keyring:)
      @path = path
      @keyring = keyring
    end

    def read
      decrypt(File.binread(path).strip)
    end

    def write(content)
      File.binwrite "#{path}.tmp", encrypt(content)
      FileUtils.mv "#{path}.tmp", path
    end

    # @private
    def to_s
      "#<Zee::EncryptedFile path=#{path}>"
    end
    alias inspect to_s

    private def encrypt(content)
      encrypted, keyring_id = *keyring.encrypt(content)
      [encrypted, keyring_id].join(SEPARATOR)
    end

    private def decrypt(encrypted)
      encrypted, keyring_id = *encrypted.split(SEPARATOR)
      keyring.decrypt(encrypted, keyring_id.to_i)
    end
  end
end
