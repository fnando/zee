# frozen_string_literal: true

require "test_helper"

module CacheStore
  class MemoryTest < Zee::Test::CacheStore
    test "implements memory cache store without encryption" do
      Dir.chdir("test/fixtures/sample_app") do
        store = Zee::CacheStore::Memory.new(encrypted: false)

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

        hash = mock("Hash")
        hash.stubs(:[]=).raises(StandardError)
        hash.stubs(:[]).raises(StandardError)
        hash.stubs(:key?).raises(StandardError)
        hash.stubs(:delete).raises(StandardError)
        hash.stubs(:clear).raises(StandardError)

        store = Zee::CacheStore::Memory.new(store: hash, encrypted: false)

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

    test "implements memory cache store" do
      Dir.chdir("test/fixtures/sample_app") do
        store = Zee::CacheStore::Memory.new(encryption: true)

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

        hash = mock("Hash")
        hash.stubs(:[]=).raises(StandardError)
        hash.stubs(:[]).raises(StandardError)
        hash.stubs(:key?).raises(StandardError)
        hash.stubs(:delete).raises(StandardError)
        hash.stubs(:clear).raises(StandardError)

        store = Zee::CacheStore::Memory.new(store: hash, encryption: true)

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
end
