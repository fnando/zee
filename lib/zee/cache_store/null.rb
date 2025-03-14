# frozen_string_literal: true

module Zee
  module CacheStore
    class Null < Base
      def initialize(*, **) #  rubocop:disable Lint/MissingSuper
        @store = {}
      end

      def increment(key, **)
        @store[key] ||= 0
        @store += 1
      end

      def decrement(key, **)
        @store[key] ||= 0
        @store -= 1
      end

      def read(*)
      end

      def delete(key, **)
        @store.delete(key)
        false
      end

      def delete_multi(*keys, **)
        keys.each_with_object({}) {|key, hash| hash[key] = nil }
      end

      def fetch_multi(*keys)
        keys.each_with_object({}) {|key, hash| hash[key] = nil }
      end

      def write(*, **)
        false
      end

      def write_multi(*, **)
        false
      end

      def fetch(*, **, &)
        yield(*, **)
      end

      def exist?(*)
        false
      end

      def clear(**)
        @store.clear
        false
      end
    end
  end
end
