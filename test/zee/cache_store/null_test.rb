# frozen_string_literal: true

require "test_helper"

class NullTest < Minitest::Test
  let(:store) { Zee::CacheStore::Null.new }

  test "fails to clear" do
    refute store.clear
  end

  test "fails to delete" do
    refute store.delete(:key)
  end

  test "fails to increment" do
    assert_nil store.increment(:key)
  end

  test "fails to decrement" do
    assert_nil store.decrement(:key)
  end

  test "fails to delete multi" do
    assert_equal 0, store.delete_multi(:key)
  end

  test "fails to write multi" do
    refute store.write_multi(:key)
  end

  test "fails to write" do
    refute store.write(:key, 1)
  end

  test "keys never exist" do
    store.write(:key, 1)

    refute store.exist?(:key)
  end

  test "evaluates fetch every time" do
    assert_equal 1, store.fetch("key") { 1 }
    assert_equal 2, store.fetch("key") { 2 }
  end

  test "evaluates fetch multi every time" do
    count = 0

    assert_equal({a: 1, b: 2}, store.fetch_multi(:a, :b) { count += 1 })
  end
end
