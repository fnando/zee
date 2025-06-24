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

      def delete(_key, **)
        false
      end

      def delete_multi(*, **)
        0
      end

      def fetch_multi(*keys)
        keys.each_with_object({}) {|key, hash| hash[key] = yield(key, self) }
      end

      def write(*, **)
        false
      end

      def write_multi(*, **)
        false
      end

      def fetch(*, **, &)
        yield(*, self)
      end

      def exist?(*)
        false
      end

      def clear(**)
        false
      end
    end
  end
end
