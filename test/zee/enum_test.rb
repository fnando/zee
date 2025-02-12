# frozen_string_literal: true

require "test_helper"

class EnumTest < Minitest::Test
  test "overrides inspect methods" do
    enum = Zee::Enum(:a, :b)

    assert_equal "Zee::Enum", enum.class.name
    assert_equal "#<Zee::Enum class>", enum.class.inspect
    assert_equal "#<Zee::Enum class>", enum.class.to_s
    assert_equal %[#<Zee::Enum a="a" b="b">], enum.inspect
  end

  test "creates enum out of array" do
    enum = Zee::Enum(:a, :b)

    assert_equal "a", enum.a
    assert_equal "b", enum.b
  end

  test "creates enum out of hash" do
    enum = Zee::Enum(a: 1, b: 2)

    assert_equal 1, enum.a
    assert_equal 2, enum.b
  end

  test "returns keys (to_a)" do
    enum = Zee::Enum(:a, :b)

    assert_equal %i[a b], enum.to_a
  end

  test "returns hash" do
    enum = Zee::Enum(:a, :b)

    assert_equal({a: "a", b: "b"}, enum.to_h)
  end

  test "returns value by key" do
    enum = Zee::Enum(:a, :b)

    assert_equal "a", enum[:a]
  end

  test "returns value by index" do
    enum = Zee::Enum(:a, :b)

    assert_equal "a", enum[0]
  end

  test "raises error when key is invalid" do
    enum = Zee::Enum(:a, :b)

    assert_raises ArgumentError, "Invalid enum index: :c" do
      enum[:c]
    end
  end

  test "raises error when index is invalid" do
    enum = Zee::Enum(:a, :b)

    assert_raises ArgumentError, "Invalid enum index: :2" do
      enum[2]
    end
  end

  test "returns values" do
    enum = Zee::Enum(:a, :b)

    assert_equal %w[a b], enum.values
  end

  test "returns keys" do
    enum = Zee::Enum(:a, :b)

    assert_equal %i[a b], enum.keys
  end

  test "iterates each key" do
    keys = []
    Zee::Enum(:a, :b).each_key { keys << _1 }

    assert_equal %i[a b], keys
  end

  test "iterates each value" do
    values = []
    Zee::Enum(:a, :b).each_value { values << _1 }

    assert_equal %w[a b], values
  end

  test "iterates key and value" do
    keys = []
    values = []
    Zee::Enum(:a, :b).each do |key, value|
      keys << key
      values << value
    end

    assert_equal %i[a b], keys
    assert_equal %w[a b], values
  end
end
