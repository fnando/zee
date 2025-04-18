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

  test "coerces value to string" do
    model_class = Class.new(Zee::Model) do
      attribute :name
    end

    model = model_class.new
    model.name = :john

    assert_equal "john", model.name
  end

  test "coerces value to integer" do
    model_class = Class.new(Zee::Model) do
      attribute :age, :integer
    end

    model = model_class.new
    model.age = "42"

    assert_equal 42, model.age
  end

  test "coerces value to boolean" do
    model_class = Class.new(Zee::Model) do
      attribute :value, :boolean
    end

    model = model_class.new

    [0, "0", false, "false", "FALSE", nil, "off", "OFF", "no", "NO"].each do |f|
      model.value = f

      refute model.value
    end

    [
      1, "1", true, "true", "TRUE", Object.new, "on", "ON", "yes", "YES"
    ].each do |t|
      model.value = t

      assert model.value
    end
  end

  test "coerces value to date" do
    model_class = Class.new(Zee::Model) do
      attribute :value, :date
    end

    model = model_class.new

    {
      "2023-01-24" => Date.new(2023, 1, 24),
      Date.new(2023, 1, 24) => Date.new(2023, 1, 24),
      Time.new(2023, 1, 24) => Date.new(2023, 1, 24),
      1_674_536_400 => Date.new(2023, 1, 24)
    }.each_with_index do |(input, expected), index|
      model.value = input

      assert_equal expected, model.value, "Failed at index=#{index}"
    end
  end

  test "fails when coercing invalid type to date" do
    model_class = Class.new(Zee::Model) do
      attribute :value, :date
    end

    model = model_class.new

    error = assert_raises(ArgumentError) do
      model.value = true
    end

    assert_equal "invalid date value: true", error.message
  end

  test "coerces value to time" do
    model_class = Class.new(Zee::Model) do
      attribute :value, :time
    end

    model = model_class.new

    {
      "2023-01-24" => Time.new(2023, 1, 24),
      "2023-01-24T23:45:21Z" => Time.utc(2023, 1, 24, 23, 45, 21),
      Date.new(2023, 1, 24) => Time.new(2023, 1, 24),
      Time.new(2023, 1, 24) => Date.new(2023, 1, 24).to_time,
      1_674_529_200 => Time.at(1_674_529_200)
    }.each_with_index do |(input, expected), index|
      model.value = input

      assert_equal expected, model.value, "Failed at index=#{index}"
    end
  end

  test "fails when coercing invalid type to time" do
    model_class = Class.new(Zee::Model) do
      attribute :value, :time
    end

    model = model_class.new

    error = assert_raises(ArgumentError) do
      model.value = true
    end

    assert_equal "invalid time value: true", error.message
  end

  test "coerces value to float" do
    model_class = Class.new(Zee::Model) do
      attribute :value, :float
    end

    model = model_class.new

    {
      "42.1" => 42.1,
      42.1 => 42.1,
      1 => 1.0
    }.each do |input, expected|
      model.value = input

      assert_equal expected, model.value
    end
  end

  test "coerces value to bigdecimal" do
    model_class = Class.new(Zee::Model) do
      attribute :value, :decimal
    end

    model = model_class.new

    {
      "42.1" => BigDecimal("42.1"),
      42.1 => BigDecimal("42.1"),
      BigDecimal(42.1, 10) => BigDecimal("42.1"), # rubocop:disable Performance/BigDecimalWithNumericArgument
      BigDecimal(1) => BigDecimal(1)
    }.each do |input, expected|
      model.value = input

      assert_equal expected, model.value
    end
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
