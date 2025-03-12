# frozen_string_literal: true

module Sequel
  module Plugins
    # Add support for encrypted attributes to Sequel models.
    #
    # N.B.: this plugin should not be used to encrypt passwords--for that, you
    # should use something like {https://github.com/codahale/bcrypt-ruby}.
    # This is meant for encrypting sensitive data you will need to access in
    # plain text (e.g. storing OAuth token from users). Passwords do not fall in
    # that category.
    #
    # ## Configuration
    #
    # As far as database schema goes:
    #
    # 1. You'll need a column to track the key that was used for encryption; by
    #    default it's called `keyring_id`.
    # 2. Every encrypted column must follow the name `encrypted_<column name>`.
    # 3. Optionally, you can also have a `<column name>_digest` to help with
    #    searching (see Lookup section below).
    #
    # @see Zee::Keyring
    #
    # @example Enable in all models
    #   Sequel::Model.plugin :encrypted_attributes
    #
    # @example Enable in a single model
    #   User.plugin :encrypted_attributes
    #
    # @example Defining encrypted attributes
    #
    #   class User < Sequel::Model
    #     keyring ENV["KEYRING"], digest_salt: ENV["KEYRING_DIGEST_SALT"]
    #     encrypt :email
    #   end
    #
    # @example JSON encode attributes
    #   encrypt :meta, encoder: JSON
    #
    # @example JSON encode attributes (with symbolized keys)
    #   encrypt :meta,
    #             encoder: Zee::Encoders::JSONEncoder
    #
    # @example Manually rotate encrypted attributes to the latest key
    #   record.keyring_rotate!
    module EncryptedAttributes
      def self.apply(model)
        require "zee/keyring"

        model.instance_eval do
          class << self
            # Track the attributes that are encrypted.
            attr_accessor :encrypted_attributes

            # The column name that holds the keyring id.
            # Defaults to `:keyring_id`.
            attr_accessor :keyring_column_name
          end

          self.encrypted_attributes = {}
          self.keyring_column_name = :keyring_id
        end
      end

      module ClassMethods
        # @api private
        def inherited(subclass)
          super

          subclass.encrypted_attributes = encrypted_attributes.dup
          subclass.keyring = keyring
          subclass.keyring_column_name = keyring_column_name
        end

        # Set the keyring for this model.
        # If no keyring is set, a new keyring is created with an empty key.
        #
        # @param keyring [Hash] the keyring to use.
        # @param digest_salt [String] the salt to use for generating digests.
        # @return [Zee::Keyring] the keyring.
        #
        # @see Zee::Keyring
        # @see Zee::Keyring#initialize
        #
        # @example Set the keyring
        #   class User < Sequel::Model
        #     keyring ENV["KEYRING"], digest_salt: ENV["KEYRING_DIGEST_SALT"]
        #   end
        #
        # @example Access the keyring directly
        #   User.keyring
        # @param [Object] encryptor
        def keyring(
          keyring = nil,
          digest_salt: nil,
          encryptor: Zee::Keyring::Encryptor::AES::AES256GCM
        )
          @keyring ||= Zee::Keyring.new({}, digest_salt: "")

          if keyring
            @keyring = Zee::Keyring.new(keyring, digest_salt:, encryptor:)
          end

          @keyring
        end

        # Set the keyring for this model.
        # @param keyring [Zee::Keyring] the keyring to use.
        # @see #keyring
        def keyring=(keyring)
          @keyring = keyring
        end

        # Define one or more encrypted attributes.
        # @param attributes [Array<Symbol>] the attributes to encrypt.
        # @param encoder [Object] the encoder to use. Must response to
        #                         `dump(data)` and `parse(string)`. Defaults
        #                         to `nil`.
        # @see JSONEncoder
        #
        # @example Define encrypted attributes
        #   class User < Sequel::Model
        #     keyring ENV["KEYRING"], digest_salt: ENV["KEYRING_DIGEST_SALT"]
        #     encrypt :email
        #   end
        #
        # @example Define encrypted attributes with a JSON encoder
        #   class User < Sequel::Model
        #     keyring ENV["KEYRING"], digest_salt: ENV["KEYRING_DIGEST_SALT"]
        #     encrypt :email, encoder: JSON
        #   end
        #
        # @example Define encrypted attributes with a JSON encoder (symbolized
        # keys).
        #   class User < Sequel::Model
        #     keyring ENV["KEYRING"], digest_salt: ENV["KEYRING_DIGEST_SALT"]
        #     encrypt :email, encoder: Zee::Encoders::JSONEncoder
        #   end
        def encrypt(*attributes, encoder: nil)
          self.encrypted_attributes ||= {}

          attributes.each do |attribute|
            encrypted_attributes[attribute.to_sym] = {encoder: encoder}

            define_encrypted_attribute_writer(attribute)
            define_encrypted_attribute_reader(attribute)
          end
        end

        # @api private
        def define_encrypted_attribute_writer(attribute)
          define_method(:"#{attribute}=") do |value|
            encrypt_column(attribute, value)
          end
        end

        # @api private
        def define_encrypted_attribute_reader(attribute)
          define_method(attribute) do
            decrypt_column(attribute)
          end
        end
      end

      module InstanceMethods
        # @api private
        def before_save
          super
          migrate_to_latest_encryption_key
        end

        # Rotate the encrypted attributes to the latest key.
        #
        # @example Rotate the encrypted attributes
        #   record.keyring_rotate!
        def keyring_rotate!
          migrate_to_latest_encryption_key
          save
        end

        # @api private
        private def encrypt_column(attribute, value)
          clear_decrypted_column_cache(attribute)
          unless encryptable_value?(value)
            return reset_encrypted_column(attribute)
          end

          encoder = self.class.encrypted_attributes[attribute][:encoder]
          value = encoder.dump(value) if encoder
          value = value.to_s

          previous_keyring_id = public_send(self.class.keyring_column_name)
          encrypted_value, keyring_id, digest =
            self.class.keyring.encrypt(value, previous_keyring_id)

          public_send(:"#{self.class.keyring_column_name}=", keyring_id)
          public_send(:"encrypted_#{attribute}=", encrypted_value)

          return unless respond_to?(:"#{attribute}_digest=")

          public_send(:"#{attribute}_digest=", digest)
        end

        # @api private
        private def decrypt_column(attribute)
          cache_name = :"@#{attribute}"

          if instance_variable_defined?(cache_name)
            return instance_variable_get(cache_name)
          end

          encrypted_value = public_send(:"encrypted_#{attribute}")

          return unless encrypted_value

          decrypted_value = self.class.keyring.decrypt(
            encrypted_value,
            public_send(self.class.keyring_column_name)
          )

          encoder = self.class.encrypted_attributes[attribute][:encoder]
          decrypted_value = encoder.parse(decrypted_value) if encoder

          instance_variable_set(cache_name, decrypted_value)
        end

        # @api private
        private def clear_decrypted_column_cache(attribute)
          cache_name = :"@#{attribute}"

          return unless instance_variable_defined?(cache_name)

          remove_instance_variable(cache_name)
        end

        # @api private
        private def reset_encrypted_column(attribute)
          public_send(:"encrypted_#{attribute}=", nil)
          if respond_to?(:"#{attribute}_digest=")
            public_send(:"#{attribute}_digest=", nil)
          end
          nil
        end

        # @api private
        private def migrate_to_latest_encryption_key
          return unless self.class.keyring.current_key

          keyring_id = self.class.keyring.current_key.id

          self.class.encrypted_attributes.each do |attribute, options|
            value = public_send(attribute)
            next unless encryptable_value?(value)

            encoder = options[:encoder]
            value = encoder.dump(value) if encoder

            encrypted_value, _, digest = self.class.keyring.encrypt(value)

            public_send(:"encrypted_#{attribute}=", encrypted_value)

            if respond_to?(:"#{attribute}_digest")
              public_send(:"#{attribute}_digest=", digest)
            end
          end

          public_send(:"#{self.class.keyring_column_name}=", keyring_id)
        end

        # @api private
        private def encryptable_value?(value)
          return false if value.nil?
          return false if value.is_a?(String) && value.empty?

          true
        end
      end
    end
  end
end
