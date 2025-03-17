# frozen_string_literal: true

module Zee
  module ViewHelpers
    module Caching
      # Cache the block of code for the given key.
      # The cache will expire in the given number of seconds. If no expiration
      # time is given, the cache will never expire.
      #
      # > [!NOTE]
      # > The cache key will include the template's MD5 digest. This means that
      # > if the template changes, the cache will be invalidated.
      #
      # @param key [String, Symbol, Array<String, Symbol>] The key to use for
      #                                                    the cache.
      # @param expires_in [Integer, nil] The number of seconds until the cache
      #                                 expires. If nil, the cache will never
      #                                 expire.
      # @return [SafeBuffer] The cached value.
      #
      # @example Caching a block
      #   ```erb
      #   <%= cache(:my_key) do %>
      #   This block will be cached.
      #   <% end %>
      #   ```
      #
      # @example Specifying caching TTL
      #   ```erb
      #   <%= cache(:my_key, expires_in: 60) do %>
      #   This block will be cached for 60 seconds.
      #   <% end %>
      #   ```
      #
      # @example Using a dynamic cache key
      #   - If the object responds to `#cache_key`, it will be used to generate
      #     the cache key.
      #   - If the object responds to `#id`, the object's id will be used.
      #   - Otherwise, the object will be used as-is, which is fine for
      #     primitive values, but probably not what you want for objects.
      #
      #   If you're using Sequel, Zee ships with a plugin to automatically
      #   define `#cache_key` on your models. Enable it
      #   with `Sequel::Model.plugin :cache_key`.
      #
      #   ```erb
      #   <%= cache([:my_key, @user]) do %>
      #   This block will be cached with a dynamic key.
      #   <% end %>
      #   ```
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
        keys =
          [current_template.cache_key, key]
          .flatten
          .map do |entry|
            if entry.respond_to?(:cache_key)
              entry.cache_key
            elsif entry.respond_to?(:id)
              entry.id
            else
              entry
            end
          end

        keys.join(COLON)
      end
    end
  end
end
