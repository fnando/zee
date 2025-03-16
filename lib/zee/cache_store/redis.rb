# frozen_string_literal: true

module Zee
  module CacheStore
    class Redis < Base
      # @api private
      # The OK response from Redis.
      # @return [String]
      OK = "OK"

      # @return [ConnectionPool] the connection pool to the Redis server.
      attr_reader :pool

      def initialize(pool:, **)
        super(**)
        @pool = pool
      end

      # @param key [String, Symbol] The key to write to.
      # @param value [Object] The value to write.
      # @param expires_in [Integer] The number of seconds to expire the key in.
      # @return [Boolean] Whether the write was successful.
      def write(key, value, expires_in: nil)
        result = @pool.with do |r|
          r.set(normalize_key(key), dump(value), ex: expires_in)
        end

        result == OK
      rescue StandardError
        false
      end

      # @param key [String, Symbol] The key to check to.
      # @return [Boolean] Whether the write was successful.
      def exist?(key)
        @pool.with {|r| r.exists(normalize_key(key)) }.positive?
      rescue StandardError
        nil
      end

      # @param key [String, Symbol] The key to read from.
      # @return [Boolean] Whether the write was successful.
      def read(key)
        @pool.with {|r| load(r.get(normalize_key(key))) }
      rescue StandardError
        nil
      end

      # @param key [String, Symbol] The key to delete.
      # @return [Boolean] Whether the write was successful.
      def delete(key)
        @pool.with {|r| r.del(normalize_key(key)) }.positive?
      rescue StandardError
        false
      end

      # @param key [String, Symbol] The key to read/write from/to.
      # @param expires_in [Integer] The number of seconds to expire the key in.
      # @return [Object] The resolved value.
      def fetch(key, expires_in: nil, &)
        key = normalize_key(key)
        value = read(key)

        unless value
          value = yield(key, self)
          return value unless write(key, value, expires_in:)
        end

        value
      end

      # @param key [String, Symbol] The key to increment.
      # @param amount [Integer] The amount to increment the value by.
      # @param expires_in [Integer] The number of seconds to expire the key in.
      # @return [Integer] the new value.
      def increment(key, amount = 1, expires_in: nil)
        key = normalize_key(key)
        future = nil

        @pool.with do |r|
          r.multi do |t|
            future = t.incrby(key, amount)
            t.expire(key, expires_in) if expires_in
          end
        end

        future.value.to_i
      rescue StandardError
        false
      end

      # @param key [String, Symbol] The key to decrement.
      # @param amount [Integer] The amount to decrement the value by.
      # @param expires_in [Integer] The number of seconds to expire the key in.
      # @return [Integer] the new value.
      def decrement(key, amount = 1, expires_in: nil)
        key = normalize_key(key)
        future = nil

        @pool.with do |r|
          r.multi do |t|
            future = t.decrby(key, amount)
            t.expire(key, expires_in) if expires_in
          end
        end

        future.value.to_i
      rescue StandardError
        false
      end

      # @param data [Hash{String => Object}] The data to write.
      # @param expires_in [Integer] The number of seconds to expire the key in.
      # @return [Boolean] Whether the write was successful.
      def write_multi(data, expires_in: nil)
        data.map {|key, value| write(key, value, expires_in:) }.all?
      end

      # @param keys [Array<String, Symbol>] The keys to read from.
      # @return [Hash{String => Object}] The resolved values.
      def read_multi(*keys)
        result = @pool.with do |r|
          r.multi {|t| keys.each {|key| t.get(normalize_key(key)) } }
        end

        result.map! {|value| load(value) }

        keys.zip(result).to_h
      rescue StandardError
        keys.zip(Array.new(keys.size)).to_h
      end

      # @param keys [Array<String, Symbol>] The keys to delete.
      # @return [Integer] The number of keys deleted.
      def delete_multi(*keys)
        result = @pool.with do |r|
          r.multi {|t| keys.each {|key| t.del(normalize_key(key)) } }
        end

        result.sum
      rescue StandardError
        0
      end

      # @param keys [Array<String, Symbol>] The keys to read/write from/to.
      # @param expires_in [Integer] The number of seconds to expire the key in.
      # @return [Hash{String => Object}] The resolved values.
      # @yieldparam key [Array<String, Hash>] The key that was not found, plus
      #                                       the options.
      def fetch_multi(*keys, expires_in: nil, &)
        result = @pool.with do |r|
          r.multi {|t| keys.each {|key| t.get(normalize_key(key)) } }
        end

        result = keys.zip(result).to_h

        result = result.each_with_object({}) do |(key, value), buffer|
          value = load(value) if value
          value = yield(key, self) if value.nil?

          buffer[key] = value
        end

        @pool.with do |r|
          r.multi do |t|
            result.each do |key, value|
              t.set(normalize_key(key), dump(value), ex: expires_in)
            end
          end
        end

        result
      rescue StandardError
        (result || keys.zip(Array.new(keys)).to_h)
          .transform_values {|key| yield(key, self) }
      end

      # Clears the storage.
      # @return [Boolean] Whether the clear was successful.
      def clear(**)
        @pool.with(&:flushdb) == OK
      rescue StandardError
        false
      end
    end
  end
end
