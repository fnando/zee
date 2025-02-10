require "base64"
require "openssl"

module Zee
  class EncryptedFile
    CIPHER = "aes-256-gcm"

    attr_reader :path, :key

    def initialize(path:, key:)
      @path = path
      @key = key
    end

    def read
      decrypt File.binread(path)
    end

    def write(content)
      File.binwrite "#{path}.tmp", encrypt(content)
      FileUtils.mv "#{path}.tmp", path
    end

    # @private
    def to_s
      "#<Zee::EncryptedFile path=#{path}>"
    end

    private def encrypt(content)
      cipher = OpenSSL::Cipher.new(CIPHER)
      cipher.encrypt
      iv = cipher.random_iv
      cipher.key = key
      cipher.iv = iv
      encrypted = cipher.update(content) + cipher.final
      auth_tag = cipher.auth_tag
      [iv, auth_tag, encrypted].map { Base64.strict_encode64(_1) }.join(";")
    end

    private def decrypt(encrypted)
      iv, auth_tag, encrypted =
        *(encrypted.split(";").map { Base64.strict_decode64(_1) })
      decipher = OpenSSL::Cipher.new(CIPHER)
      decipher.decrypt
      decipher.key = key
      decipher.iv = iv
      decipher.auth_tag = auth_tag
      decipher.update(encrypted) + decipher.final
    end
  end
end
