# frozen_string_literal: true

require "test_helper"

class AcceptanceTest < Minitest::Test
  test "validates acceptance of attribute" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :tos
      validates_acceptance_of :tos
    end

    model = model_class.new

    refute model.valid?
    assert_includes model.errors[:tos], "must be accepted"

    model.tos = true

    assert model.valid?
  end

  test "validates acceptance of attribute with custom accept values" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :tos
      validates_acceptance_of :tos, accept: %w[1 yes]
    end

    model = model_class.new

    refute model.valid?

    model.tos = "yes"

    assert model.valid?
  end

  test "uses custom message" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :tos
      validates_acceptance_of :tos,
                              message: "was not accepted"
    end

    model = model_class.new

    refute model.valid?
    assert_includes model.errors[:tos], "was not accepted"
  end

  test "uses translated message" do
    store_translations(
      :en,
      {
        zee: {
          model: {errors: {acceptance: "was not accepted"}}
        }
      }
    )

    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :tos
      validates_acceptance_of :tos
    end

    model = model_class.new

    refute model.valid?
    assert_includes model.errors[:tos], "was not accepted"
  end
end
