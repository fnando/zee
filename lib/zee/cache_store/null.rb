# frozen_string_literal: true

module Zee
  module CacheStore
    class Null < Base
      def initialize(*, **)
        super
      end

      def increment(_key, **)
      end

      def decrement(_key, **)
      end

      def read(*)
      end

      def delete(_key, **) # rubocop:disable Naming/PredicateMethod
        false
      end

      def delete_multi(*, **)
        0
      end

      def fetch_multi(*keys)
        keys.each_with_object({}) {|key, hash| hash[key] = yield(key, self) }
      end

      def write(*, **) # rubocop:disable Naming/PredicateMethod
        false
      end

      def write_multi(*, **) # rubocop:disable Naming/PredicateMethod
        false
      end

      def fetch(*, **, &)
        yield(*, self)
      end

      def exist?(*)
        false
      end

      def clear(**) # rubocop:disable Naming/PredicateMethod
        false
      end
    end
  end
end
