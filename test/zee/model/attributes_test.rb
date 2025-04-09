# frozen_string_literal: true

require "test_helper"

class AttributesTest < Minitest::Test
  test "defines string attribute" do
    model_class = Class.new(Zee::Model) do
      attribute :name
    end

    model = model_class.new(name: "Jane")

    assert_equal "Jane", model.name
    assert_equal "Jane", model[:name]
    assert_equal "Jane", model.attributes[:name]
  end

  test "assigns value" do
    model_class = Class.new(Zee::Model) do
      attribute :name
    end

    model = model_class.new(name: "Jane")
    model[:name] = "John"

    assert_equal "John", model.name
  end

  test "returns default value" do
    model_class = Class.new(Zee::Model) do
      attribute :name, default: "Stranger"
    end

    model = model_class.new

    assert_equal "Stranger", model.name
  end

  test "skips coercion when assigning nil" do
    model_class = Class.new(Zee::Model) do
      attribute :name
    end

    model = model_class.new
    model.name = nil

    assert_nil model.name
  end

  test "inherits attributes" do
    parent_class = Class.new(Zee::Model) do
      attribute :name
      attribute :email
    end

    child_class = Class.new(parent_class)
    expected = {
      name: {type: :string, default: nil},
      email: {type: :string, default: nil}
    }

    assert_equal expected, child_class.attributes
  end
end
