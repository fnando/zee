# frozen_string_literal: true

require "base64"
require "openssl"

module Zee
  class EncryptedFile
    ValidationError = Class.new(StandardError)

    CIPHER = "aes-256-gcm"
    AUTH_TAG_LENGTH = 12
    SEPARATOR = "--"

    attr_reader :path, :key, :cipher

    def initialize(path:, key:)
      @cipher = OpenSSL::Cipher.new(CIPHER)
      validate_key!(key)

      @path = path
      @key = key
    end

    def read
      @cipher = OpenSSL::Cipher.new(CIPHER)
      decrypt File.binread(path).strip
    end

    def write(content)
      @cipher = OpenSSL::Cipher.new(CIPHER)
      File.binwrite "#{path}.tmp", encrypt(content)
      FileUtils.mv "#{path}.tmp", path
    end

    # @private
    def to_s
      "#<Zee::EncryptedFile path=#{path}>"
    end
    alias inspect to_s

    private def encode(text)
      Base64.strict_encode64(text)
    end

    private def decode(text)
      Base64.strict_decode64(text)
    end

    private def encrypt(content)
      cipher.encrypt
      iv = cipher.random_iv
      cipher.key = key
      cipher.iv = iv
      encrypted = cipher.update(content) + cipher.final
      auth_tag = cipher.auth_tag
      [encrypted, iv, auth_tag].map { encode(_1) }.join(SEPARATOR)
    end

    # :nocov:
    private def validate_key!(key)
      length = key.bytesize

      return if length == cipher.key_len

      raise ValidationError,
            "invalid key length; " \
            "expected #{cipher.key_len}, got #{length}"
    end

    private def validate_iv!(iv)
      length = iv.bytesize

      return if length == cipher.iv_len

      raise ValidationError,
            "invalid iv length; " \
            "expected #{cipher.iv_len}, got #{length}"
    end

    private def validate_auth_tag!(auth_tag)
      length = auth_tag.bytesize

      return if length == AUTH_TAG_LENGTH

      raise ValidationError,
            "invalid auth_tag length; " \
            "expected #{AUTH_TAG_LENGTH}, got #{length}"
    end
    # :nocov:

    private def decrypt(encrypted)
      encrypted, iv, auth_tag = *encrypted.split(SEPARATOR).map { decode(_1) }

      validate_iv!(iv)
      validate_auth_tag!(iv)

      cipher.decrypt
      cipher.key = key
      cipher.iv = iv
      cipher.auth_tag = auth_tag
      cipher.update(encrypted) + cipher.final
    end
  end
end
