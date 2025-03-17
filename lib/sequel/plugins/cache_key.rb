# frozen_string_literal: true

module Sequel
  module Plugins
    # The cache_key plugin adds a cache_key method to the model instance.
    # It uses the pluralized model name, the model's ID, and the updated_at
    # timestamp if it's available.
    #
    # It's useful for caching the model instance in a cache store and views.
    #
    # Using this plugin also includes:
    #
    # - [timestamps](https://sequel.jeremyevans.net/rdoc-plugins/classes/Sequel/Plugins/Timestamps.html)
    #   plugin with the update_on_create option set to `true`.
    # - {Naming} plugin.
    module CacheKey
      SLASH = "/"

      module InstanceMethods
        # Returns a cache key for the model instance.
        # It uses the pluralized model name, the model's ID, and the updated_at
        # timestamp if it's available.
        #
        # @return [String]
        #
        # @example
        #   user.cache_key # users/1/1742193065
        def cache_key
          [
            self.class.naming.plural, id,
            (updated_at.to_i if respond_to?(:updated_at))
          ].compact.join(SLASH)
        end
      end

      # @api private
      def self.apply(model)
        model.plugin :timestamps, update_on_create: true
        model.plugin :naming
        model.plugin :cache_key
        model.include(InstanceMethods)
      end
    end
  end
end
