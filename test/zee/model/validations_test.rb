# frozen_string_literal: true

require "test_helper"

class ValidationsTest < Minitest::Test
  test "inherits validations" do
    parent_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :name
      validates_presence_of :name
    end

    child_class = Class.new(parent_class)
    model = child_class.new

    refute model.valid?
  end

  test "accepts blank" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :name
      validates_presence_of :name, allow_blank: true
    end

    model = model_class.new(name: "")

    assert model.valid?
  end

  test "accepts nil" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :name
      validates_presence_of :name, allow_nil: true
    end

    model = model_class.new(name: nil)

    assert model.valid?
  end

  test "validates when if conditions are met" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :name
      validates_presence_of :name, if: :condition

      private def condition
        true
      end
    end

    model = model_class.new(name: nil)

    refute model.valid?
  end

  test "does not validate when if conditions aren't met" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :name
      validates_presence_of :name, if: :condition

      private def condition
        false
      end
    end

    model = model_class.new(name: nil)

    assert model.valid?
  end

  test "validates when unless conditions aren't met" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :name
      validates_presence_of :name, unless: :condition

      private def condition
        false
      end
    end

    model = model_class.new(name: nil)

    refute model.valid?
  end

  test "does not validate when unless conditions are met" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :name
      validates_presence_of :name, unless: :condition

      private def condition
        true
      end
    end

    model = model_class.new(name: nil)

    assert model.valid?
  end
end
