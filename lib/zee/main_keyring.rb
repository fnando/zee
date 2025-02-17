# frozen_string_literal: true

module Zee
  class MainKeyring
    MissingKeyError = Class.new(StandardError)

    def self.read(env)
      raw = ENV[ZEE_KEYRING]
      key_file = "config/secrets/#{env}.key"

      return parse(raw) if raw
      return parse(File.read(key_file)) if File.file?(key_file)

      raise MissingKeyError, "Set ZEE_KEYRING or create #{key_file}"
    end

    def self.parse(key)
      data = JSON.parse(key)
      digest_salt = data.delete("digest_salt")

      Keyring.new(
        data,
        digest_salt:,
        encryptor: Keyring::Encryptor::AES::AES256GCM
      )
    end
  end
end
