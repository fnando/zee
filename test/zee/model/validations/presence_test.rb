# frozen_string_literal: true

require "test_helper"

class PresenceTest < Minitest::Test
  test "validates presence of attribute" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :name
      validates_presence_of :name
    end

    model = model_class.new(name: nil)

    refute model.valid?
    assert model.invalid?
    assert_includes model.errors[:name], "can't be blank"
  end

  test "uses custom error message" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :name
      validates_presence_of :name, message: "is required"
    end

    model = model_class.new(name: nil)

    refute model.valid?
    assert_includes model.errors[:name], "is required"
  end

  test "uses translated error message" do
    store_translations :en, {zee: {model: {errors: {presence: "is required"}}}}

    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :name
      validates_presence_of :name
    end

    model = model_class.new(name: nil)

    refute model.valid?
    assert_includes model.errors[:name], "is required"
  end
end
