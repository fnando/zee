# frozen_string_literal: true

require "test_helper"

module CacheStore
  class MemoryTest < Zee::Test::CacheStore
    fake_store = Object.new
    def fake_store.method_missing(*, **) # rubocop:disable Style/MissingRespondToMissing
      raise StandardError
    end

    keyring = Zee::Keyring.load(
      "test/fixtures/sample_app/config/secrets/test.key"
    )

    test "fails when encrypting without a keyring" do
      error = assert_raises(Zee::CacheStore::MissingKeyringError) do
        Zee::CacheStore::Memory.new(encrypt: true, keyring: nil)
      end

      assert_equal "keyring must be set when using encryption", error.message
    end

    test "uses different coder" do
      hash = {}
      store = Zee::CacheStore::Memory.new(
        store: hash,
        encrypt: false,
        keyring:,
        coder: Marshal
      )

      store.write(:data, {a: 1})

      assert_equal({a: 1}, store.read(:data))
      assert_equal({a: 1}, Marshal.load(hash["data"])) # rubocop:disable Security/MarshalLoad
    end

    test_group "without encryption" do
      store = Zee::CacheStore::Memory.new(encrypt: false, keyring:)

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

      store = Zee::CacheStore::Memory.new(
        store: fake_store,
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
      store = Zee::CacheStore::Memory.new(encrypt: true, keyring:)

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

      store = Zee::CacheStore::Memory.new(
        store: fake_store,
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
