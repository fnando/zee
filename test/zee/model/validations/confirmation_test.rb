# frozen_string_literal: true

require "test_helper"

class ConfirmationTest < Minitest::Test
  test "validates confirmation of attribute" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :email
      validates_confirmation_of :email
    end

    model = model_class.new(email: "EMAIL", email_confirmation: "WRONG_EMAIL")

    refute model.valid?
    assert_includes model.errors[:email_confirmation], "doesn't match email"

    model.email_confirmation = "EMAIL"

    assert model.valid?
  end

  test "uses custom message" do
    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :email
      validates_confirmation_of :email,
                                message: "is not the same as %{attribute}"
    end

    model = model_class.new(email: "EMAIL", email_confirmation: "WRONG_EMAIL")

    refute model.valid?
    assert_includes model.errors[:email_confirmation],
                    "is not the same as email"
  end

  test "uses translated message" do
    store_translations(
      :en,
      {
        zee: {
          model: {errors: {confirmation: "is not the same as %{attribute}"}}
        }
      }
    )

    model_class = Class.new(Zee::Model) do
      def self.name
        "User"
      end

      attribute :email
      validates_confirmation_of :email
    end

    model = model_class.new(email: "EMAIL", email_confirmation: "WRONG_EMAIL")

    refute model.valid?
    assert_includes model.errors[:email_confirmation],
                    "is not the same as email"
  end
end
