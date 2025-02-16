# frozen_string_literal: true

module Zee
  class Keyring
    # @private
    module Encryptor
      module AES
        class Base
          SEPARATOR = "--"

          def self.build_cipher
            OpenSSL::Cipher.new(cipher_name)
          end

          def self.key_size
            @key_size ||= build_cipher.key_len
          end

          def self.encrypt(key, message)
            cipher = build_cipher
            cipher.encrypt
            iv = cipher.random_iv
            cipher.iv  = iv
            cipher.key = key.encryption_key
            encrypted = cipher.update(message) + cipher.final
            data = if cipher.authenticated?
                     [iv, cipher.auth_tag, encrypted]
                   else
                     [iv, encrypted]
                   end
            hmac = hmac_digest(key.signing_key, data.join(SEPARATOR))

            Base64.strict_encode64([hmac].concat(data).join(SEPARATOR))
          end

          def self.decrypt(key, message)
            cipher = build_cipher
            cipher.decrypt

            hmac, *data = *Base64.strict_decode64(message).split(SEPARATOR)

            expected_hmac = hmac_digest(key.signing_key, data.join(SEPARATOR))

            unless verify_signature(expected_hmac, hmac)
              raise InvalidAuthentication,
                    "Expected HMAC to be " \
                    "#{Base64.strict_encode64(expected_hmac)}; " \
                    "got #{Base64.strict_encode64(hmac)} instead"
            end

            iv, auth_tag, encrypted = *data
            encrypted = auth_tag unless cipher.authenticated?

            cipher.iv = iv
            cipher.key = key.encryption_key
            cipher.auth_tag = auth_tag if cipher.authenticated?
            cipher.update(encrypted) + cipher.final
          end

          def self.hmac_digest(key, bytes)
            OpenSSL::HMAC.digest("sha256", key, bytes)
          end

          def self.verify_signature(expected, actual)
            expected_bytes = expected.bytes.to_a
            actual_bytes = actual.bytes.to_a

            actual_bytes.inject(0) do |accum, byte|
              accum | byte ^ expected_bytes.shift
            end.zero?
          end
        end

        class AES128CBC < Base
          def self.cipher_name
            "AES-128-CBC"
          end
        end

        class AES192CBC < Base
          def self.cipher_name
            "AES-192-CBC"
          end
        end

        class AES256CBC < Base
          def self.cipher_name
            "AES-256-CBC"
          end
        end

        class AES256GCM < Base
          def self.cipher_name
            "AES-256-GCM"
          end
        end
      end
    end
  end
end
