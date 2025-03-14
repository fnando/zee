# frozen_string_literal: true

module Zee
  module CacheStore
    class Redis < Base
      OK = "OK"

      def initialize(pool:, **options)
        super(**options)
        @pool = pool
        @options = options
      end

      def write(key, value, **)
        @pool.with {|r| r.set(key, dump(value)) } == OK
      rescue StandardError
        false
      end

      def exist?(key, **)
        @pool.with {|r| r.exists(key) }.positive?
      rescue StandardError
        nil
      end

      def read(key, **)
        @pool.with {|r| load(r.get(key)) }
      rescue StandardError
        nil
      end

      def delete(key, **)
        @pool.with {|r| r.del(key) }.positive?
      rescue StandardError
        false
      end

      def fetch(key, **options, &)
        value = read(key)

        unless value
          value = yield(key, options)
          return value unless write(key, value, **options)
        end

        value
      end

      def increment(key, amount = 1, **)
        @pool.with {|r| r.incrby(key, amount).to_i }
      rescue StandardError
        false
      end

      def decrement(key, amount = 1, **)
        @pool.with {|r| r.decrby(key, amount).to_i }
      rescue StandardError
        false
      end

      def write_multi(data, **)
        data.map {|key, value| write(key, value, **) }.all?
      end

      def read_multi(*keys, **)
        result = @pool.with do |r|
          r.multi {|t| keys.each {|key| t.get(key) } }
        end

        result.map! {|value| load(value) }

        keys.zip(result).to_h
      rescue StandardError
        keys.zip(Array.new(keys.size)).to_h
      end

      def delete_multi(*keys, **)
        result = @pool.with do |r|
          r.multi {|t| keys.each {|key| t.del(key) } }
        end

        result.sum
      rescue StandardError
        0
      end

      def fetch_multi(*keys, **options, &)
        result = @pool.with do |r|
          r.multi {|t| keys.each {|key| t.get(key) } }
        end

        result = keys.zip(result).to_h

        result.each_with_object({}) do |(key, value), buffer|
          value = load(value) if value
          value = yield(key, options) if value.nil?

          buffer[key] = value
        end
      rescue StandardError
        (result || keys.zip(Array.new(keys)).to_h)
          .transform_values {|key| yield(key, options) }
      end

      def clear(**)
        @pool.with(&:flushdb) == OK
      rescue StandardError
        false
      end
    end
  end
end
