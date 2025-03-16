# frozen_string_literal: true

module Zee
  module CacheStore
    class Memory < Base
      # Error raised when unable to write to cache store.
      UnableToWriteError = Class.new(StandardError)

      # @return [Hash] the store.
      attr_reader :store

      # Initializes the cache store.
      def initialize(store: {}, **)
        @store = store
        super(**)
      end

      # Deletes key from the cache.
      #
      # @param key [String, Symbol] the cache key.
      # @return [Boolean] Returns `true` if the deletion succeeded, or `false`
      #                   if the deletion failed.
      def delete(key, **)
        returned = true
        store.delete(key.to_s) { returned = false }
        returned
      rescue StandardError
        false
      end

      # Deletes multiple keys from the cache.
      #
      # @param keys [Array<String, Symbol>] the cache key.
      # @return [Integer] Returns the number of deleted entries.
      def delete_multi(*keys, **)
        keys.sum {|key| delete(key) ? 1 : 0 }
      end

      # Increment a value in the cache. If the key does not exist, it will be
      # initialized to 0.
      #
      # @param key [String, Symbol] the cache key.
      # @param amount [Integer] the amount to increment the value by. Defaults
      #                         to 1.
      # @return [Integer] the new value.
      def increment(key, amount = 1, **)
        key = key.to_s
        count = read(key) || 0
        count += amount
        return false unless write(key, count)

        count
      end

      # Decrement a value in the cache. If the key does not exist, it will be
      # initialized to 0.
      #
      # @param key [String, Symbol] the cache key.
      # @param amount [Integer] the amount to decrement the value by. Defaults
      #                         to 1.
      # @return [Integer] the new value.
      def decrement(key, amount = 1, **)
        key = key.to_s
        count = read(key) || 0
        count -= amount
        return false unless write(key, count)

        count
      end

      # Reads from the cache.
      #
      # @param key [String, Symbol] the cache key.
      # @return [Boolean] Returns `true` if the write succeeded, or `false` if
      #                   the write failed.
      def read(key, **)
        load(store[key.to_s])
      rescue StandardError
        nil
      end

      # Reads multiple keys from the cache.
      #
      # @param keys [Array<String, Symbol>] the cache keys.
      # @return [Hash] Returns a hash with all retrieved values. If a key
      #                doesn't exist or it fails to read, then it's value will
      #                be `nil`.
      def read_multi(*keys, **)
        keys.each_with_object({}) do |key, buffer|
          buffer[key] = read(key, **)
        end
      end

      # Write to cache store.
      # @param key [String, Hash] the cache key. When key is a Hash, then this
      #                           will do a multi-write.
      # @param value [Object] the value that will be stored in the cache.
      def write(key, value = nil, **)
        store[key.to_s] = dump(value)
      rescue StandardError
        false
      end

      # @api private
      private def write!(key, value, **)
        return if write(key, value, **)

        raise UnableToWriteError, "failed to write key #{k.inspect}"
      end

      # Writes multiple values to the cache.
      #
      # @param values [Hash] the value that will be written to cache.
      # @return [Boolean] Returns `true` if the write succeeded, or `false` if
      #                   one or more writes fail.
      def write_multi(values, **)
        values.each {|k, v| write!(k, v, **) }
        true
      rescue StandardError
        false
      end

      # Fetches data from the cache, using the given key. If there is data in
      # the cache with the given key, then that data is returned.
      #
      # If there is no such data in the cache (a cache miss), the provided block
      # will be executed with the key and provided options, and the return value
      # will be written to the cache.
      #
      # @param key [Symbol, String] the cache key.
      # @return [Object]
      def fetch(key, **, &)
        return read(key, **) if exist?(key, **)

        value = yield(key, self)
        write(key, value, **)
        value
      end

      # Fetches data from the cache, using the given keys. If there is data in
      # the cache with the given key, then that data is returned.
      #
      # If there is no such data in the cache (a cache miss), the provided block
      # will be executed with the key and provided options, and the return value
      # will be written to the cache.
      #
      # @param keys [Array<Symbol, String>] the cache keys.
      # @return [Hash]
      def fetch_multi(*keys, **, &)
        keys.each_with_object({}) do |key, buffer|
          buffer[key.to_s] = fetch(key, **, &)
        end
      end

      # Returns `true` if the cache contains an entry for the given key.
      #
      # @param key [String, Symbol] the cache key.
      # @return [Boolean]
      def exist?(key)
        store.key?(key.to_s)
      rescue StandardError
        nil
      end

      # Clears the storage.
      #
      # @return [Boolean]
      def clear(**)
        store.clear
        true
      rescue StandardError
        false
      end
    end
  end
end
