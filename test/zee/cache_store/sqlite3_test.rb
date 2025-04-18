# frozen_string_literal: true

require "test_helper"

module CacheStore
  class SQLite3Test < Zee::Test::CacheStore
    keyring = Zee::Keyring.load(
      "test/fixtures/sample_app/config/secrets/test.key"
    )

    test "uses different coder" do
      store = Zee::CacheStore::SQLite3.new(
        url: "sqlite3::memory:",
        encrypt: false,
        keyring:,
        coder: Marshal
      )

      store.write(:data, {a: 1})

      data = store.instance_variable_get(:@db)
                  .execute("select content from cache_store")
                  .flatten
                  .first

      assert_equal({a: 1}, store.read(:data))
      assert_equal({a: 1}, Marshal.load(data)) #  rubocop:disable Security/MarshalLoad
    end

    test_group "without encryption" do
      store = Zee::CacheStore::SQLite3.new(
        url: "sqlite3::memory:",
        encrypt: false,
        keyring:
      )

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
        Zee::CacheStore::SQLite3.new(
          url: "sqlite3::memory:",
          namespace: "myapp",
          keyring:,
          encrypt: false
        )
      )

      path = File.join(Dir.pwd, "tmp/file.db")
      FileUtils.mkdir_p(File.dirname(path))

      store = Zee::CacheStore::SQLite3.new(
        url: "sqlite3://#{path}",
        encrypt: false,
        keyring:
      )

      store.instance_variable_get(:@db).execute("drop table cache_store")

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
      store = Zee::CacheStore::SQLite3.new(url: "sqlite3::memory:",
                                           encrypt: true, keyring:)

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

      store = Zee::CacheStore::SQLite3.new(
        url: "sqlite3::memory:",
        encrypt: false,
        keyring:
      )

      store.instance_variable_get(:@db).execute("drop table cache_store")

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
