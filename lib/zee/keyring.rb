# frozen_string_literal: true

module Zee
  # Simple encryption-at-rest with key rotation support for Ruby.
  #
  # == Encryption
  #
  # By default, AES-128-CBC is the algorithm used for encryption. This algorithm
  # uses 16 bytes keys, but you're required to use a key that's double the size
  # because half of that keys will be used to generate the HMAC. The first 16
  # bytes will be used as the encryption key, and the last 16 bytes will be used
  # to generate the HMAC.
  #
  # Using random data base64-encoded is the recommended way. You can easily
  # generate keys by using the following command:
  #
  #     $ dd if=/dev/urandom bs=32 count=1 2>/dev/null | openssl base64 -A
  #     qUjOJFgZsZbTICsN0TMkKqUvSgObYxnkHDsazTqE5tM=
  #
  # Include the result of this command in the `value` section of the key
  # description in the keyring. Half this key is used for encryption, and half
  # for the HMAC.
  #
  # == Key Size
  #
  # The key size depends on the algorithm being used. The key size should be
  # double the size as half of it is used for HMAC computation.
  #
  # - `aes-128-cbc`: 16 bytes (encryption) + 16 bytes (HMAC).
  # - `aes-192-cbc`: 24 bytes (encryption) + 24 bytes (HMAC).
  # - `aes-256-cbc`: 32 bytes (encryption) + 32 bytes (HMAC).
  # - `aes-256-gcm`: 32 bytes (encryption) + 32 bytes (HMAC).
  #
  # == About the encrypted message
  #
  # Initialization vectors (IV) should be unpredictable and unique; ideally,
  # they will be cryptographically random. They do not have to be secret: IVs
  # are typically just added to ciphertext messages unencrypted. It may sound
  # contradictory that something has to be unpredictable and unique, but does
  # not have to be secret; it is important to remember that an attacker must not
  # be able to predict ahead of time what a given IV will be.
  #
  # With that in mind, the format for `AES-128-CBC`, `AES-192-CBC` and
  # `AES-256-CBC`{Zee::Keyring} is:
  #
  #     message_hmac = hmac(iv + "--" + encrypted)
  #     base64(message_hmac + "--" + unencrypted iv + "--" + encrypted message)
  #
  # For `AES-256-GCM`, the format also includes the auth tag:
  #
  #     base64(
  #       message_hmac + "--" +
  #       unencrypted iv + "--" +
  #       unencrypted auth tag + "--" +
  #       encrypted message
  #     )
  #
  # If you're planning to migrate from other encryption mechanisms or read
  # encrypted values from the database without using {Zee::Keyring}, make sure
  # you account for this. The HMAC is 32-bytes long and the IV is 16-bytes long.
  #
  # == Keyring
  #
  # Keys are managed through a keyring--a short JSON document describing your
  # encryption keys. The keyring must be a JSON object mapping numeric ids of
  # the keys to the key values. A keyring must have at least one key. For
  # example:
  #
  #     {
  #       "1": "uDiMcWVNTuz//naQ88sOcN+E40CyBRGzGTT7OkoBS6M=",
  #       "2": "VN8UXRVMNbIh9FWEFVde0q7GUA1SGOie1+FgAKlNYHc="
  #     }
  # ```
  #
  # The `id` is used to track which key encrypted which piece of data; a key
  # with a larger id is assumed to be newer. The value is the actual bytes of
  # the encryption key.
  #
  # == Looking Up Records
  #
  # One tricky aspect of encryption is looking up records by known secret. E.g.
  # `User.where(email: "john@example.com")` is trivial with plain text fields,
  # but impossible with the model defined as above.
  #
  # If a column `<attribute>_digest` exists, then a SHA1 digest from the value
  # will be saved. This will allow you to lookup by that value instead and add
  # unique indexes. You don't have to use a hashing salt, but it's highly
  # recommended; this way you can avoid leaking your users' info via rainbow
  # tables.
  #
  #     User.where(email: User.keyring.digest("john@example.com")).first
  #
  # == Key Rotation
  #
  # Because attr_keyring uses a keyring, with access to multiple keys at once,
  # key rotation is fairly straightforward: if you add a key to the keyring with
  # a higher id than any other key, that key will automatically be used for
  # encryption when records are either created or updated. Any keys that are no
  # longer in use can be safely removed from the keyring.
  #
  # To check if an existing key with id `123` is still in use, run:
  #
  #     # For a large dataset, you may want to index the `keyring_id` column.
  #     User.where(keyring_id: 123).empty?
  #
  # You may not want to wait for records to be updated (e.g. key leaking). In
  # that case, you can rollout a key rotation:
  #
  #     User.where(keyring_id: 1234).find_each do |user|
  #       user.keyring_rotate!
  #     end
  #
  # @example Basic usage
  #   keyring = Zee::Keyring.new(
  #     {"1" => "uDiMcWVNTuz//naQ88sOcN+E40CyBRGzGTT7OkoBS6M="},
  #     digest_salt: "<custom salt>"
  #   )
  #
  #   # STEP 1: Encrypt message using latest encryption key.
  #   encrypted, keyring_id, digest = keyring.encrypt("super secret")
  #
  #   puts "🔒 #{encrypted}"
  #   puts "🔑 #{keyring_id}"
  #   puts "🔎 #{digest}"
  #
  #   # STEP 2: Decrypted message using encryption key defined by keyring id.
  #   decrypted = keyring.decrypt(encrypted, keyring_id)
  #   puts "✉️ #{decrypted}"
  #
  # @example Change encryption algorithm
  #   # You can choose between `AES-128-CBC`, `AES-192-CBC`, `AES-256-CBC` and
  #   # `AES-256-GCM`. By default, `AES-128-CBC` will be used.
  #   #
  #   # To specify the encryption algorithm, set the `encryption` option. The
  #   # following example uses `AES-256-CBC`.
  #   keyring = Keyring.new(
  #     "1" => "uDiMcWVNTuz//naQ88sOcN+E40CyBRGzGTT7OkoBS6M=",
  #     encryptor: Keyring::Encryptor::AES::AES256CBC,
  #     digest_salt: "<custom salt>"
  #   )
  #
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

    # The encryptor that will be used on this keyring.
    # Defaults to {Encryptor::AES::AES128CBC}.
    attr_reader :encryptor

    # The digest salt used to generate digests.
    # @return [String]
    attr_reader :digest_salt

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
        Key.new(id:, key: value, size: encryptor.key_size)
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
      @keyring << Key.new(id:, key:, size: encryptor.key_size)
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
        encryptor.encrypt(key, message),
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
      encryptor.decrypt(key, message)
    end

    # Returns the SHA1 digest of a message.
    # @param message [String]
    # @return [String]
    def digest(message)
      Digest::SHA1.hexdigest("#{message}#{digest_salt}")
    end
  end
end
