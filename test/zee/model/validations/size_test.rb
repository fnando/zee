# frozen_string_literal: true

require "test_helper"

class SizeTest < Minitest::Test
  test "validates minimum size" do
    model_class = Class.new(Zee::Model) do
      attribute :username, :string
      validates_size_of :username, minimum: 3
    end

    model = model_class.new(username: "ab")

    refute model.valid?
    assert_includes model.errors[:username],
                    "is too short (minimum is 3 characters)"

    model.username = "abc"

    assert model.valid?
  end

  test "uses custom message with minimum size validation" do
    model_class = Class.new(Zee::Model) do
      attribute :username, :string
      validates_size_of :username,
                        minimum: 3,
                        message: "should be at least %{count} chars long"
    end

    model = model_class.new(username: "ab")

    refute model.valid?
    assert_includes model.errors[:username], "should be at least 3 chars long"
  end

  test "uses :too_short message with minimum size validation" do
    model_class = Class.new(Zee::Model) do
      attribute :username, :string
      validates_size_of :username,
                        minimum: 3,
                        too_short: "should be at least %{count} chars long"
    end

    model = model_class.new(username: "ab")

    refute model.valid?
    assert_includes model.errors[:username], "should be at least 3 chars long"
  end

  test "uses translated message with minimum size validation" do
    store_translations(
      :en,
      zee: {
        model: {
          errors: {
            too_short: "should be at least %{count} chars long"
          }
        }
      }
    )

    model_class = Class.new(Zee::Model) do
      attribute :username, :string
      validates_size_of :username, minimum: 3
    end

    model = model_class.new(username: "ab")

    refute model.valid?
    assert_includes model.errors[:username], "should be at least 3 chars long"
  end

  test "validates maximum size" do
    model_class = Class.new(Zee::Model) do
      attribute :username, :string
      validates_size_of :username, maximum: 3
    end

    model = model_class.new(username: "abcd")

    refute model.valid?
    assert_includes model.errors[:username],
                    "is too long (maximum is 3 characters)"

    model.username = "abc"

    assert model.valid?
  end

  test "uses custom message with maximum size validation" do
    model_class = Class.new(Zee::Model) do
      attribute :username, :string
      validates_size_of :username,
                        maximum: 3,
                        message: "should be at most %{count} chars long"
    end

    model = model_class.new(username: "abcd")

    refute model.valid?
    assert_includes model.errors[:username], "should be at most 3 chars long"
  end

  test "uses :too_long message with maximum size validation" do
    model_class = Class.new(Zee::Model) do
      attribute :username, :string
      validates_size_of :username,
                        maximum: 3,
                        too_long: "should be at least %{count} chars long"
    end

    model = model_class.new(username: "abcd")

    refute model.valid?
    assert_includes model.errors[:username], "should be at least 3 chars long"
  end

  test "uses translated message with maximum size validation" do
    store_translations(
      :en,
      zee: {
        model: {
          errors: {
            too_long: "should be at most %{count} chars long"
          }
        }
      }
    )

    model_class = Class.new(Zee::Model) do
      attribute :username, :string
      validates_size_of :username, maximum: 3
    end

    model = model_class.new(username: "abcd")

    refute model.valid?
    assert_includes model.errors[:username], "should be at most 3 chars long"
  end

  test "validates is exaclty the specified size" do
    model_class = Class.new(Zee::Model) do
      attribute :username, :string
      validates_size_of :username, is: 3
    end

    model = model_class.new(username: "abcd")

    refute model.valid?
    assert_includes model.errors[:username],
                    "is the wrong size (should be 3 characters)"

    model.username = "abc"

    assert model.valid?
  end

  test "uses custom message with exact size validation" do
    model_class = Class.new(Zee::Model) do
      attribute :username, :string
      validates_size_of :username,
                        is: 3,
                        message: "should be exactly %{count} chars long"
    end

    model = model_class.new(username: "ab")

    refute model.valid?
    assert_includes model.errors[:username], "should be exactly 3 chars long"
  end

  test "uses :wrong_size message with exact size validation" do
    model_class = Class.new(Zee::Model) do
      attribute :username, :string
      validates_size_of :username,
                        is: 3,
                        wrong_size: "should be exactly %{count} chars long"
    end

    model = model_class.new(username: "ab")

    refute model.valid?
    assert_includes model.errors[:username], "should be exactly 3 chars long"
  end

  test "uses translated message with exact size validation" do
    store_translations(
      :en,
      zee: {
        model: {
          errors: {
            wrong_size: "should be exactly %{count} chars long"
          }
        }
      }
    )

    model_class = Class.new(Zee::Model) do
      attribute :username, :string
      validates_size_of :username, is: 3
    end

    model = model_class.new(username: "abcd")

    refute model.valid?
    assert_includes model.errors[:username], "should be exactly 3 chars long"
  end

  test "validates size is within range" do
    model_class = Class.new(Zee::Model) do
      attribute :username, :string
      validates_size_of :username, in: 3..4
    end

    model = model_class.new(username: "ab")

    refute model.valid?
    assert_includes model.errors[:username],
                    "is too short (minimum is 3 characters)"

    model.username = "abcde"

    refute model.valid?
    assert_includes model.errors[:username],
                    "is too long (maximum is 4 characters)"

    model.username = "abc"

    assert model.valid?
  end
end
