# frozen_string_literal: true

require "test_helper"

class ExclusionTest < Minitest::Test
  test "validates attribute exclusion within list" do
    model_class = Class.new(Zee::Model) do
      attribute :username
      validates_exclusion_of :username, in: %w[admin]
    end

    model = model_class.new(username: "admin")

    refute model.valid?
    assert_includes model.errors[:username], "is not a valid username"

    model.username = "john"

    assert model.valid?
  end

  test "validates attribute exclusion within range" do
    model_class = Class.new(Zee::Model) do
      attribute :age, :integer
      validates_exclusion_of :age, in: ..17
    end

    model = model_class.new(age: 11)

    refute model.valid?
    assert_includes model.errors[:age], "is not a valid age"

    model.age = 42

    assert model.valid?
  end

  test "uses custom error message" do
    model_class = Class.new(Zee::Model) do
      attribute :username
      validates_exclusion_of :username,
                             in: %w[admin root],
                             message: "can't be a restricted username"
    end

    model = model_class.new(username: "admin")

    refute model.valid?
    assert_includes model.errors[:username], "can't be a restricted username"
  end

  test "uses translated error message" do
    store_translations(
      :en,
      zee: {model: {errors: {exclusion: "can't be a restricted %{attribute}"}}}
    )

    model_class = Class.new(Zee::Model) do
      attribute :username
      validates_exclusion_of :username, in: %w[admin root]
    end

    model = model_class.new(username: "admin")

    refute model.valid?
    assert_includes model.errors[:username],
                    "can't be a restricted username"
  end
end
