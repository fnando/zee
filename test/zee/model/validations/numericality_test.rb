# frozen_string_literal: true

require "test_helper"

class NumericalityTest < Minitest::Test
  test "validates numericality with only integers" do
    model_class = Class.new(Zee::Model) do
      attr_accessor :width

      validates_numericality_of :width, only_integer: true
    end

    model = model_class.new
    model.width = 1.1

    refute model.valid?
    assert_includes model.errors[:width], "is not an integer"

    model.width = 1

    assert model.valid?
  end

  test "validates numericality with greater than" do
    model_class = Class.new(Zee::Model) do
      attribute :width, :integer
      validates_numericality_of :width, greater_than: 1
    end

    model = model_class.new
    model.width = 1

    refute model.valid?
    assert_includes model.errors[:width], "is not greater than 1"

    model.width = 2

    assert model.valid?
  end

  test "validates numericality with greater than or equal to" do
    model_class = Class.new(Zee::Model) do
      attribute :width, :integer
      validates_numericality_of :width, greater_than_or_equal_to: 1
    end

    model = model_class.new
    model.width = 0

    refute model.valid?
    assert_includes model.errors[:width], "is not greater than or equal to 1"

    model.width = 1

    assert model.valid?

    model.width = 2

    assert model.valid?
  end

  test "validates numericality with equal to" do
    model_class = Class.new(Zee::Model) do
      attribute :width, :integer
      validates_numericality_of :width, equal_to: 1
    end

    model = model_class.new
    model.width = 0

    refute model.valid?
    assert_includes model.errors[:width], "is not equal to 1"

    model.width = 1

    assert model.valid?

    model.width = 2

    refute model.valid?
  end

  test "validates numericality with less than" do
    model_class = Class.new(Zee::Model) do
      attribute :width, :integer
      validates_numericality_of :width, less_than: 1
    end

    model = model_class.new
    model.width = 1

    refute model.valid?
    assert_includes model.errors[:width], "is not less than 1"

    model.width = 0

    assert model.valid?
  end

  test "validates numericality with less than or equal to" do
    model_class = Class.new(Zee::Model) do
      attribute :width, :integer
      validates_numericality_of :width, less_than_or_equal_to: 1
    end

    model = model_class.new
    model.width = 2

    refute model.valid?
    assert_includes model.errors[:width], "is not less than or equal to 1"

    model.width = 0

    assert model.valid?

    model.width = 1

    assert model.valid?
  end

  test "validates numericality with other than" do
    model_class = Class.new(Zee::Model) do
      attribute :width, :integer
      validates_numericality_of :width, other_than: 1
    end

    model = model_class.new
    model.width = 1

    refute model.valid?
    assert_includes model.errors[:width], "is different than 1"

    model.width = 0

    assert model.valid?

    model.width = 2

    assert model.valid?
  end

  test "validates numericality with odd" do
    model_class = Class.new(Zee::Model) do
      attribute :width, :integer
      validates_numericality_of :width, odd: true
    end

    model = model_class.new
    model.width = 0

    refute model.valid?
    assert_includes model.errors[:width], "is not an odd number"

    model.width = 1

    assert model.valid?
  end

  test "validates numericality with even" do
    model_class = Class.new(Zee::Model) do
      attribute :width, :integer
      validates_numericality_of :width, even: true
    end

    model = model_class.new
    model.width = 1

    refute model.valid?
    assert_includes model.errors[:width], "is not an even number"

    model.width = 0

    assert model.valid?
  end
end
