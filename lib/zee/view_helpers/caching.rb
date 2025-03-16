# frozen_string_literal: true

module Zee
  module ViewHelpers
    module Caching
      # Cache the block of code for the given key.
      # The cache will expire in the given number of seconds. If no expiration
      # time is given, the cache will never expire.
      #
      # @param key [String, Symbol, Array<String, Symbol>] The key to use for
      #                                                    the cache.
      # @param expires_in [Integer, nil] The number of seconds until the cache
      #                                 expires. If nil, the cache will never
      #                                 expire.
      def cache(key, expires_in: nil, &block)
        cache_key = cache_key_for(key)
        called = false

        value = cache_store.fetch(cache_key, expires_in:) do
          called = true
          capture(&block)
        end

        value = SafeBuffer.new(value) unless called
        value
      end

      # Create a helper method for the cache store, so it can be overridden.
      # @return [Zee::CacheStore::Base]
      def cache_store
        Zee.app.config.cache
      end

      # @api private
      #
      # Build a cache key for the given key.
      #
      # @param key [String, Symbol, Array<String, Symbol>]
      # @return [String]
      def cache_key_for(key)
        [current_template.cache_key, key]
          .flatten
          .map { _1.respond_to?(:cache_key) ? _1.cache_key : _1 }
          .join(COLON)
      end
    end
  end
end
