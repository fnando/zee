# frozen_string_literal: true

require "test_helper"

class InclusionTest < Minitest::Test
  test "validates attribute inclusion within list" do
    model_class = Class.new(Zee::Model) do
      attribute :status
      validates_inclusion_of :status, in: %w[pending complete]
    end

    model = model_class.new(status: "invalid")

    refute model.valid?
    assert_includes model.errors[:status], "is not a valid status"

    model.status = "pending"

    assert model.valid?
  end

  test "validates attribute inclusion within range" do
    model_class = Class.new(Zee::Model) do
      attribute :delay, :integer
      validates_inclusion_of :delay, in: 1..10
    end

    model = model_class.new(delay: 11)

    refute model.valid?
    assert_includes model.errors[:delay], "is not a valid delay"

    model.delay = 5

    assert model.valid?
  end

  test "uses custom error message" do
    model_class = Class.new(Zee::Model) do
      attribute :status
      validates_inclusion_of :status,
                             in: %w[pending complete],
                             message: "must be either pending or complete"
    end

    model = model_class.new(status: nil)

    refute model.valid?
    assert_includes model.errors[:status], "must be either pending or complete"
  end

  test "uses translated error message" do
    store_translations(
      :en,
      zee: {model: {errors: {inclusion: "must be either pending or complete"}}}
    )

    model_class = Class.new(Zee::Model) do
      attribute :status
      validates_inclusion_of :status, in: %w[pending complete]
    end

    model = model_class.new(status: nil)

    refute model.valid?
    assert_includes model.errors[:status], "must be either pending or complete"
  end
end
