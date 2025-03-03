# frozen_string_literal: true

require "base64"
require "openssl"

module Zee
  class EncryptedFile
    # @api private
    SEPARATOR = "--"

    # Where the encrypted file will be saved.
    # @return [String]
    attr_reader :path

    # The [Keyring] that will be used to encrypt and decrypt the file.
    # @return [String]
    attr_reader :keyring

    # @param path [String]
    # @param keyring [Keyring]
    # @return [EncryptedFile]
    def initialize(path:, keyring:)
      @path = path
      @keyring = keyring
    end

    # Read the encrypted file.
    # @return [String] The encrypted content.
    def read
      decrypt(File.binread(path).strip)
    end

    # Write the encrypted file.
    # @param content [String] The unencrypted content.
    # @return [void]
    def write(content)
      File.binwrite "#{path}.tmp", encrypt(content)
      FileUtils.mv "#{path}.tmp", path
    end

    # @api private
    def to_s
      "#<Zee::EncryptedFile path=#{path}>"
    end
    alias inspect to_s

    # @api private
    private def encrypt(content)
      encrypted, keyring_id = *keyring.encrypt(content)
      [encrypted, keyring_id].join(SEPARATOR)
    end

    # @api private
    private def decrypt(encrypted)
      encrypted, keyring_id = *encrypted.split(SEPARATOR)
      keyring.decrypt(encrypted, keyring_id.to_i)
    end
  end
end
