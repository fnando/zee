# frozen_string_literal: true

module Zee
  # Cache store module.
  #
  # This module provides a set of classes that implement the cache store
  # interface. The cache store interface is a simple way to interact with
  # different cache stores.
  #
  # It's important that adapters call `#dump(data)` and `#load(data)`, so
  # the data is serialized and deserialized correctly.
  #
  # The default coder is `JSON`, but it can be changed by passing a different
  # coder (i.e. an object that responds to `#load(data)` and `#dump(data)`).
  #
  # The default keyring is `Zee.app.keyring`, but it can be changed by passing
  # a different keyring with `.new(keyring:)`.
  #
  # For a basic example, see {CacheStore::Memory}.
  module CacheStore
    # Raised when a method is not implemented by an adapter.
    NotImplementedError = Class.new(StandardError)

    # Base class for cache stores.
    # @abstract
    class Base
      # @return [Boolean] whether the cache store will encrypt the data.
      attr_reader :encrypt
      alias encrypt? encrypt

      # @return [Hash] the options passed to the cache store.
      attr_reader :options

      # @return [Zee::Keyring] the keyring used to encrypt and decrypt data.
      attr_reader :keyring

      # @return [#load, #dump] the coder used to serialize and deserialize data.
      #                        By default, it uses `JSON`.
      attr_reader :coder

      # Initializes the cache store.
      # Adapters must implement this method, even if they want to ignore any
      # provided options.
      def initialize(
        coder: ::JSON,
        encrypt: true,
        keyring: Zee.app.keyring,
        **options
      )
        @encrypt = encrypt
        @options = options
        @keyring = keyring
        @coder = coder
      end

      # @abstract
      #
      # Increment a value in the cache. If the key does not exist, it will be
      # initialized to 0.
      #
      # @param key [String, Symbol] the cache key.
      # @param amount [Integer] the amount to increment the value by. Defaults
      #                         to 1.
      # @param options [Hash{Symbol => Object}] Options are passed to the
      #                                         underlying cache implementation.
      # @return [Integer] the new value.
      # @raise [NotImplementedError] if the method is not implemented.
      def increment(key, amount = 1, **options)
        # :nocov:
        raise NotImplementedError
        # :nocov:
      end

      # @abstract
      #
      # Decrement a value in the cache. If the key does not exist, it will be
      # initialized to 0.
      #
      # @param key [String, Symbol] the cache key.
      # @param amount [Integer] the amount to decrement the value by. Defaults
      #                         to 1.
      # @param options [Hash{Symbol => Object}] Options are passed to the
      #                                         underlying cache implementation.
      # @return [Integer] the new value.
      # @raise [NotImplementedError] if the method is not implemented.
      def decrement(key, amount = 1, **options)
        # :nocov:
        raise NotImplementedError
        # :nocov:
      end

      # @abstract
      #
      # Deletes key from the cache.
      #
      # @param key [String, Symbol] the cache key.
      # @param options [Hash{Symbol => Object}] Options are passed to the
      #                                         underlying cache implementation.
      # @return [Boolean] Returns `true` if the deletion succeeded, or `false`
      #                   if the deletion failed.
      def delete(key, **options)
        # :nocov:
        raise NotImplementedError
        # :nocov:
      end

      # @abstract
      #
      # Deletes multiple keys from the cache.
      #
      # @param keys [Array<String, Symbol>] the cache key.
      # @param options [Hash{Symbol => Object}] Options are passed to the
      #                                         underlying cache implementation.
      # @return [Integer] Returns the number of deleted entries.
      def delete_multi(*keys, **options)
        # :nocov:
        raise NotImplementedError
        # :nocov:
      end

      # @abstract
      #
      # Reads from the cache.
      #
      # @param key [String, Symbol] the cache key.
      # @param options [Hash{Symbol => Object}] Options are passed to the
      #                                         underlying cache implementation.
      # @return [Boolean] Returns `true` if the write succeeded, or `false` if
      #                   the write failed.
      def read(key, **options)
        # :nocov:
        raise NotImplementedError
        # :nocov:
      end

      # @abstract
      #
      # Reads multiple keys from the cache.
      #
      # @param keys [Array<String, Symbol>] the cache keys.
      # @param options [Hash{Symbol => Object}] Options are passed to the
      #                                         underlying cache implementation.
      # @return [Hash] Returns a hash with all retrieved values. If a key
      #                doesn't exist or it fails to read, then it's value will
      #                be `nil`.
      def read_multi(keys, **options)
        # :nocov:
        raise NotImplementedError
        # :nocov:
      end

      # @abstract
      #
      # Writes to the cache.
      #
      # @param key [String, Symbol] the cache key.
      # @param value [Object] the value that will be written to cache.
      # @param options [Hash{Symbol => Object}] Options are passed to the
      #                                         underlying cache implementation.
      # @return [Boolean] Returns `true` if the write succeeded, or `false` if
      #                   the write failed.
      def write(key, value, **options)
        # :nocov:
        raise NotImplementedError
        # :nocov:
      end

      # @abstract
      #
      # Writes multiple values to the cache.
      #
      # @param values [Hash] the value that will be written to cache.
      # @param options [Hash{Symbol => Object}] Options are passed to the
      #                                         underlying cache implementation.
      # @return [Boolean] Returns `true` if the write succeeded, or `false` if
      #                   one or more writes fail.
      def write_multi(values, **options)
        # :nocov:
        raise NotImplementedError
        # :nocov:
      end

      # @abstract
      #
      # Fetches data from the cache, using the given key. If there is data in
      # the cache with the given key, then that data is returned.
      #
      # If there is no such data in the cache (a cache miss), the provided block
      # will be executed with the key and provided options, and the return value
      # will be written to the cache.
      #
      # @param key [Symbol, String] the cache key.
      # @param options [Hash{Symbol => Object}] Options are passed to the
      #                                         underlying cache implementation.
      # @return [Object]
      def fetch(key, **options, &)
        # :nocov:
        raise NotImplementedError
        # :nocov:
      end

      # @abstract
      #
      # Fetches data from the cache, using the given keys. If there is data in
      # the cache with the given key, then that data is returned.
      #
      # If there is no such data in the cache (a cache miss), the provided block
      # will be executed with the key and provided options, and the return value
      # will be written to the cache.
      #
      # @param keys [Array<Symbol, String>] the cache keys.
      # @param options [Hash{Symbol => Object}] Options are passed to the
      #                                         underlying cache implementation.
      # @return [Hash]
      def fetch_multi(*keys, **options, &)
        # :nocov:
        raise NotImplementedError
        # :nocov:
      end

      # @abstract
      #
      # Returns `true` if the cache contains an entry for the given key.
      #
      # @param key [String, Symbol] the cache key.
      # @param options [Hash{Symbol => Object}] Options are passed to the
      #                                         underlying cache implementation.
      # @return [Boolean]
      def exist?(key, **options)
        # :nocov:
        raise NotImplementedError
        # :nocov:
      end

      # @abstract
      #
      # Clears the storage.
      #
      # @param options [Hash{Symbol => Object}] Options are passed to the
      #                                         underlying cache implementation.
      # @return [Boolean]
      def clear(**options)
        # :nocov:
        raise NotImplementedError
        # :nocov:
      end

      private def load(data)
        data = keyring.decrypt(*JSON.parse(data)) if encrypt?
        coder.load(data)
      end

      private def dump(data)
        data = coder.dump(data)
        data = JSON.dump(keyring.encrypt(data).take(2)) if encrypt?
        data
      end
    end
  end
end
