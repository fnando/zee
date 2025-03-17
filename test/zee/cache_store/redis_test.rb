# frozen_string_literal: true

require "test_helper"

module CacheStore
  class RedisTest < Zee::Test::CacheStore
    keyring = Zee::Keyring.load(
      "test/fixtures/sample_app/config/secrets/test.key"
    )

    fake_pool = Object.new
    def fake_pool.method_missing(*, **) # rubocop:disable Style/MissingRespondToMissing
      raise Redis::BaseError
    end

    test "uses different coder" do
      pool = ConnectionPool.new { ::Redis.new }
      store = Zee::CacheStore::Redis.new(
        pool:,
        encrypt: false,
        keyring:,
        coder: Marshal
      )

      store.write(:data, {a: 1})

      data = pool.with {|r| r.get(:data) }

      assert_equal({a: 1}, store.read(:data))
      assert_equal({a: 1}, Marshal.load(data)) # rubocop:disable Security/MarshalLoad
    end

    test_group "without encryption" do
      pool = ConnectionPool.new { ::Redis.new }
      store = Zee::CacheStore::Redis.new(pool:, encrypt: false, keyring:)

      setup { pool.with(&:flushdb) }

      assert_successful_write(store)
      assert_successful_read(store)
      assert_successful_delete(store)
      assert_successful_fetch(store)
      assert_successful_clear(store)
      assert_successful_increment(store)
      assert_successful_decrement(store)
      assert_successful_write_multi(store)
      assert_successful_read_multi(store)
      assert_successful_delete_multi(store)
      assert_successful_fetch_multi(store)
      assert_expiring_write(store)
      assert_expiring_write_multi(store)
      assert_expiring_fetch(store)
      assert_expiring_fetch_multi(store)
      assert_expiring_increment(store)
      assert_expiring_decrement(store)
      assert_namespacing(
        Zee::CacheStore::Redis.new(
          pool:,
          namespace: "myapp",
          keyring:,
          encrypt: false
        )
      )

      store = Zee::CacheStore::Redis.new(
        pool: fake_pool,
        encrypt: false,
        keyring:
      )

      assert_failed_write(store)
      assert_failed_read(store)
      assert_failed_delete(store)
      assert_failed_fetch(store)
      assert_failed_clear(store)
      assert_failed_increment(store)
      assert_failed_decrement(store)
      assert_failed_write_multi(store)
      assert_failed_read_multi(store)
      assert_failed_delete_multi(store)
      assert_failed_fetch_multi(store)
    end

    test_group "with encryption" do
      pool = ConnectionPool.new { ::Redis.new }
      store = Zee::CacheStore::Redis.new(pool:, encrypt: true, keyring:)

      assert_successful_write(store)
      assert_successful_read(store)
      assert_successful_delete(store)
      assert_successful_fetch(store)
      assert_successful_clear(store)
      assert_successful_increment(store)
      assert_successful_decrement(store)
      assert_successful_write_multi(store)
      assert_successful_read_multi(store)
      assert_successful_delete_multi(store)
      assert_successful_fetch_multi(store)

      store = Zee::CacheStore::Redis.new(
        pool: fake_pool,
        encrypt: true,
        keyring:
      )

      assert_failed_write(store)
      assert_failed_read(store)
      assert_failed_delete(store)
      assert_failed_fetch(store)
      assert_failed_clear(store)
      assert_failed_increment(store)
      assert_failed_decrement(store)
      assert_failed_write_multi(store)
      assert_failed_read_multi(store)
      assert_failed_delete_multi(store)
      assert_failed_fetch_multi(store)
    end
  end
end
