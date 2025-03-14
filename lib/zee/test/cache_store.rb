# frozen_string_literal: true

module Zee
  class Test < Minitest::Test
    class CacheStore < Test
      def random_key
        "key#{SecureRandom.hex(4)}"
      end

      def assert_successful_write(store)
        key = random_key

        assert store.write(key, "value")
        assert store.exist?(key.to_sym)
        assert store.exist?(key.to_s)
      end

      def assert_failed_write(store)
        key = random_key

        refute store.write(key, "value")
        refute store.exist?(key.to_sym)
        refute store.exist?(key.to_s)
      end

      def assert_successful_write_multi(store)
        key1 = random_key
        key2 = random_key

        assert store.write_multi({key1 => 1, key2 => 2})
        assert store.exist?(key1)
        assert_equal 1, store.read(key1)
        assert store.exist?(key2)
        assert_equal 2, store.read(key2)
      end

      def assert_failed_write_multi(store)
        key1 = random_key
        key2 = random_key

        refute store.write_multi({key1 => 1, key2 => 2})
      end

      def assert_successful_read(store)
        key = random_key

        assert store.write(key, "value")
        assert_equal "value", store.read(key.to_sym)
        assert_equal "value", store.read(key.to_s)
      end

      def assert_failed_read(store)
        assert_nil store.read(random_key)
      end

      def assert_successful_read_multi(store)
        key1 = random_key
        key2 = random_key

        assert_equal({key1 => nil, key2 => nil}, store.read_multi(key1, key2))

        store.write(key1, 1)
        store.write(key2, 2)

        assert_equal({key1 => 1, key2 => 2}, store.read_multi(key1, key2))
      end

      def assert_failed_read_multi(store)
        key1 = random_key
        key2 = random_key

        assert_equal({key1 => nil, key2 => nil}, store.read_multi(key1, key2))
      end

      def assert_successful_delete(store)
        key = random_key

        assert store.write(key, "value")
        assert store.delete(key)
        refute store.delete(key)
      end

      def assert_failed_delete(store)
        refute store.delete(random_key)
      end

      def assert_successful_delete_multi(store)
        key1 = random_key
        key2 = random_key

        store.write(key1, 1)
        store.write(key2, 2)

        assert_equal 2, store.delete_multi(key1, key2)
        assert_equal 0, store.delete_multi(key1, key2)
      end

      def assert_failed_delete_multi(store)
        assert_equal 0, store.delete_multi(random_key, random_key)
      end

      def assert_successful_fetch(store)
        key = random_key
        yield_key = nil
        yield_options = nil

        block = proc do |*args|
          args += [{}]
          yield_key, yield_options = *args
          "value"
        end

        assert_equal "value", store.fetch(key, &block)
        assert_equal key, yield_key
        assert_empty yield_options
        assert store.exist?(key)
      end

      def assert_failed_fetch(store)
        value = store.fetch(random_key) do # rubocop:disable Style/RedundantFetchBlock
          "value"
        end

        assert_equal "value", value
      end

      def assert_successful_fetch_multi(store)
        key1 = random_key
        key2 = random_key
        yield_key = []
        yield_options = []

        block = proc do |yk, yo|
          yield_key << yk
          yield_options << yo
          "value for #{yk}"
        end

        assert_equal(
          {key1 => "value for #{key1}", key2 => "value for #{key2}"},
          store.fetch_multi(key1, key2, &block)
        )

        store.write(key1, "stored value")

        assert_equal(
          {key1 => "stored value", key2 => "value for #{key2}"},
          store.fetch_multi(key1, key2, &block)
        )
      end

      def assert_failed_fetch_multi(store)
        key1 = random_key
        key2 = random_key

        value = store.fetch_multi(key1, key2) do |key|
          "value for #{key}"
        end

        assert_equal "value for #{key1}", value[key1]
        assert_equal "value for #{key2}", value[key2]
      end

      def assert_successful_clear(store)
        key = random_key

        store.write(key, "value")

        assert store.clear
        refute store.exist?(key)
      end

      def assert_failed_clear(store)
        refute store.clear
      end

      def assert_successful_increment(store)
        key = random_key

        assert_equal 1, store.increment(key)
        assert_equal 3, store.increment(key, 2)
        assert_equal 3, store.read(key)
      end

      def assert_failed_increment(store)
        refute store.increment(random_key)
      end

      def assert_successful_decrement(store)
        key = random_key

        assert_equal(-1, store.decrement(key))
        assert_equal(-3, store.decrement(key, 2))
        assert_equal(-3, store.read(key))
      end

      def assert_failed_decrement(store)
        refute store.decrement(random_key)
      end
    end
  end
end
