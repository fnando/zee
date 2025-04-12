# frozen_string_literal: true

require "test_helper"

class FormatTest < Minitest::Test
  test "raises when both :with and :without are provided" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :email
    end

    error = assert_raises ArgumentError do
      model_class.validates_format_of :email, with: /@/, without: /spam/i
    end

    assert_equal "Either :with or :without must be supplied (but not both)",
                 error.message
  end

  test "raises when both :with and :without aren't provided" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :email
    end

    error = assert_raises ArgumentError do
      model_class.validates_format_of :email
    end

    assert_equal "Either :with or :without must be supplied (but not both)",
                 error.message
  end

  test "raises when both :with is not valid type" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :email
    end

    error = assert_raises ArgumentError do
      model_class.validates_format_of :email, with: "fails"
    end

    assert_equal ":with must be either Regexp or respond to #call(value)",
                 error.message
  end

  test "raises when regex contains multiline anchor but :multiline is false" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :email
    end

    error = assert_raises ArgumentError do
      model_class.validates_format_of :email, with: /^\w+@\w+$/i
    end

    assert_equal ":with is using multiline anchors (^ or $) but :multiline " \
                 "is not set to true",
                 error.message
  end

  test "validates format of attribute using :with" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :email
      validates_format_of :email, with: /@/
    end

    model = model_class.new(email: "INVALID")

    refute model.valid?
    assert_includes model.errors[:email], "is invalid"

    model.email = "me@example.com"

    assert model.valid?
  end

  test "validates multiline format of attribute using :with" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :email
      validates_format_of :email, with: /^[\w.]+@[\w.]+$/m, multiline: true
    end

    model = model_class.new(email: "INVALID")

    refute model.valid?
    assert_includes model.errors[:email], "is invalid"

    model.email = "\nme@example.com\n"

    assert model.valid?
  end

  test "validates format of attribute using :without" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :email
      validates_format_of :email, without: /spam/
    end

    model = model_class.new(email: "spam@example.com")

    refute model.valid?
    assert_includes model.errors[:email], "is invalid"

    model.email = "me@example.com"

    assert model.valid?
  end

  test "validates multiline format of attribute using :without" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :email
      validates_format_of :email, without: /^spam@[\w.]+$/m, multiline: true
    end

    model = model_class.new(email: "\nspam@example.com\n")

    refute model.valid?
    assert_includes model.errors[:email], "is invalid"

    model.email = "\nme@example.com\n"

    assert model.valid?
  end

  test "uses custom message with :with" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :email
      validates_format_of :email, with: /@/, message: "must be an email"
    end

    model = model_class.new(email: "INVALID")

    refute model.valid?
    assert_includes model.errors[:email], "must be an email"
  end

  test "uses custom message with :without" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :email
      validates_format_of :email,
                          without: /spam/,
                          message: "must not be a spam account"
    end

    model = model_class.new(email: "spam")

    refute model.valid?
    assert_includes model.errors[:email], "must not be a spam account"
  end

  test "uses translated message with :with" do
    store_translations(
      :en,
      zee: {
        model: {
          errors: {
            format: "must be valid"
          }
        }
      }
    )

    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :email
      validates_format_of :email, with: /@/
    end

    model = model_class.new(email: "INVALID")

    refute model.valid?
    assert_includes model.errors[:email], "must be valid"
  end
end
