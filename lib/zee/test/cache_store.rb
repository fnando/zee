# frozen_string_literal: true

module Zee
  class Test < Minitest::Test
    class CacheStore < Test
      using Core::String

      def random_key
        "key#{SecureRandom.hex(4)}"
      end

      def self.build_store_name(store)
        store_name =
          Dry::Inflector.new.underscore(store.class.name).split("/").last
        "#{store_name} #{@group_name}"
      end

      def self.test_group(name)
        @group_name = name
        yield
        @group_name = nil
      end

      def self.assert_successful_write(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts successful write" do
          key = random_key

          assert store.write(key, "value")
          assert store.exist?(key.to_sym)
          assert store.exist?(key.to_s)
        end
      end

      def self.assert_expiring_write(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts successful expiring write" do
          slow_test
          key = random_key

          assert store.write(key, "value", expires_in: 1)
          assert store.exist?(key.to_sym)
          sleep 1.1
          refute store.exist?(key.to_sym)
        end
      end

      def self.assert_failed_write(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts failed write" do
          key = random_key

          refute store.write(key, "value")
          refute store.exist?(key.to_sym)
          refute store.exist?(key.to_s)
        end
      end

      def self.assert_successful_write_multi(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts successful write multi" do
          key1 = random_key
          key2 = random_key

          assert store.write_multi({key1 => 1, key2 => 2})
          assert store.exist?(key1)
          assert_equal 1, store.read(key1).to_i
          assert store.exist?(key2)
          assert_equal 2, store.read(key2).to_i
        end
      end

      def self.assert_expiring_write_multi(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts expiring write multi" do
          slow_test

          key1 = random_key
          key2 = random_key

          assert store.write_multi({key1 => 1, key2 => 2}, expires_in: 1)
          assert store.exist?(key1)
          assert store.exist?(key2)
          sleep 1.1
          refute store.exist?(key1)
          refute store.exist?(key2)
        end
      end

      def self.assert_failed_write_multi(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts failed write multi" do
          key1 = random_key
          key2 = random_key

          refute store.write_multi({key1 => 1, key2 => 2})
        end
      end

      def self.assert_successful_read(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts successful read" do
          key = random_key

          assert store.write(key, "value")
          assert_equal "value", store.read(key.to_sym)
          assert_equal "value", store.read(key.to_s)
        end
      end

      def self.assert_failed_read(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts failed read" do
          assert_nil store.read(random_key)
        end
      end

      def self.assert_successful_read_multi(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts successful read multi" do
          key1 = random_key
          key2 = random_key

          assert_equal({key1 => nil, key2 => nil}, store.read_multi(key1, key2))

          store.write(key1, 1)
          store.write(key2, 2)
          multi = store.read_multi(key1, key2).transform_values(&:to_i)

          assert_equal({key1 => 1, key2 => 2}, multi)
        end
      end

      def self.assert_failed_read_multi(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts failed read multi" do
          key1 = random_key
          key2 = random_key

          assert_equal({key1 => nil, key2 => nil}, store.read_multi(key1, key2))
        end
      end

      def self.assert_successful_delete(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts successful delete" do
          key = random_key

          assert store.write(key, "value")
          assert store.delete(key)
          refute store.delete(key)
        end
      end

      def self.assert_failed_delete(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts failed delete" do
          refute store.delete(random_key)
        end
      end

      def self.assert_successful_delete_multi(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts successful delete multi" do
          key1 = random_key
          key2 = random_key

          store.write(key1, 1)
          store.write(key2, 2)

          assert_equal 2, store.delete_multi(key1, key2)
          assert_equal 0, store.delete_multi(key1, key2)
        end
      end

      def self.assert_failed_delete_multi(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts failed delete multi" do
          assert_equal 0, store.delete_multi(random_key, random_key)
        end
      end

      def self.assert_successful_fetch(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts successful fetch" do
          key = random_key
          yield_key = nil
          yield_self = nil

          block = proc do |*args|
            args += [{}]
            yield_key, yield_self = *args
            SecureRandom.random_number(100)
          end

          first_call = store.fetch(key, &block)

          assert_instance_of Integer, first_call
          assert_equal key, yield_key
          assert_same store, yield_self
          assert store.exist?(key)

          second_call = store.fetch(key, &block)

          assert_equal first_call, second_call
        end
      end

      def self.assert_expiring_fetch(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts successful expiring fetch" do
          slow_test

          key = random_key
          count = 0

          block = proc do
            count += 1
            count
          end

          assert_equal 1, store.fetch(key, expires_in: 1, &block)
          assert store.exist?(key)
          sleep 1.1
          assert_equal 2, store.fetch(key, expires_in: 1, &block)
          assert store.exist?(key)
        end
      end

      def self.assert_failed_fetch(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts failed fetch" do
          value = store.fetch(random_key) do
            "value"
          end

          assert_equal "value", value
        end
      end

      def self.assert_successful_fetch_multi(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts successful fetch multi" do
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

          assert store.write(key1, "stored value")

          assert_equal(
            {key1 => "stored value", key2 => "value for #{key2}"},
            store.fetch_multi(key1, key2, &block)
          )
        end
      end

      def self.assert_expiring_fetch_multi(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts successful expiring fetch multi" do
          slow_test

          key1 = random_key
          key2 = random_key
          count = 0
          block = proc { count += 1 }

          assert_equal(
            {key1 => 1, key2 => 2},
            store.fetch_multi(key1, key2, expires_in: 1, &block)
          )
          assert store.exist?(key1)
          assert store.exist?(key2)
          sleep 1.1

          assert_equal(
            {key1 => 3, key2 => 4},
            store.fetch_multi(key1, key2, expires_in: 1, &block)
          )
          assert store.exist?(key1)
          assert store.exist?(key2)
        end
      end

      def self.assert_failed_fetch_multi(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts failed fetch multi" do
          key1 = random_key
          key2 = random_key

          value = store.fetch_multi(key1, key2) do |key|
            "value for #{key}"
          end

          assert_equal "value for #{key1}", value[key1]
          assert_equal "value for #{key2}", value[key2]
        end
      end

      def self.assert_successful_clear(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts successful clear" do
          key = random_key

          store.write(key, "value")

          assert store.clear
          refute store.exist?(key)
        end
      end

      def self.assert_failed_clear(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts failed clear" do
          refute store.clear
        end
      end

      def self.assert_successful_increment(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts successful increment" do
          key = random_key

          assert_equal 1, store.increment(key)
          assert_equal 3, store.increment(key, 2)
          assert_equal 3, store.read(key)
        end
      end

      def self.assert_expiring_increment(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts successful expiring increment" do
          slow_test
          key = random_key

          assert_equal 1, store.increment(key, expires_in: 1)
          assert_equal 1, store.read(key).to_i
          sleep 1.1
          refute store.exist?(key)
        end
      end

      def self.assert_failed_increment(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts failed increment" do
          refute store.increment(random_key)
        end
      end

      def self.assert_successful_decrement(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts successful decrement" do
          key = random_key

          assert_equal(-1, store.decrement(key))
          assert_equal(-3, store.decrement(key, 2))
          assert_equal(-3, store.read(key).to_i)
        end
      end

      def self.assert_expiring_decrement(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts successful expiring decrement" do
          slow_test
          key = random_key

          assert_equal(-1, store.decrement(key, expires_in: 1))
          assert_equal(-1, store.read(key).to_i)
          sleep 1.1
          refute store.exist?(key)
        end
      end

      def self.assert_failed_decrement(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts failed decrement" do
          refute store.decrement(random_key)
        end
      end

      def self.assert_namespacing(store)
        store_name = build_store_name(store)

        test "[#{store_name}] asserts namespacing" do
          key = random_key

          assert store.write(key, "value")
          assert store.exist?(key)
          stored = store.fetch_multi(key) { "missing #{_1}" }
          assert_equal({key => "value"}, stored)
          assert store.delete(key)
          refute store.exist?(key)
          stored = store.fetch_multi(key) { "missing #{_1}" }
          assert_equal({key => "missing #{key}"}, stored)
        end
      end
    end
  end
end
