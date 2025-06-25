# frozen_string_literal: true

require "test_helper"

class ErrorsTest < Minitest::Test
  test "generates human attribute name for anonymous classes" do
    assert_equal "full name",
                 Zee::Model::Errors.new(Class.new)
                                   .human_attribute_name(:full_name)
  end

  test "returns human attribute from generic translation" do
    store_translations(
      :en,
      zee: {
        model: {
          attributes: {
            name: "full name"
          }
        }
      }
    )

    assert_equal "full name",
                 Zee::Model::Errors.new(Class.new)
                                   .human_attribute_name(:name)
  end

  test "returns human attribute from model attribute translation" do
    model = Class.new do
      def self.naming
        @naming ||= Zee::Naming::Name.new("User")
      end
    end

    store_translations(
      :en,
      zee: {
        model: {
          attributes: {
            user: {
              name: "full name"
            }
          }
        }
      }
    )

    assert_equal "full name",
                 Zee::Model::Errors.new(model.new)
                                   .human_attribute_name(:name)
  end

  test "iterates over errors" do
    errors = Zee::Model::Errors.new(nil)
    errors.add(:name, :blank, message: "can't be blank")
    actual = {}
    expected = {name: ["can't be blank"]}

    errors.each {|attr, list| actual[attr] = list }

    assert_equal expected, actual
  end

  test "uses default error description" do
    errors = Zee::Model::Errors.new(nil)
    errors.add(:email, :already_taken)
    actual = {}
    expected = {email: ["already taken"]}

    errors.each {|attr, list| actual[attr] = list }

    assert_equal expected, actual
  end

  test "uses translated error" do
    store_translations(
      :en,
      zee: {
        model: {
          errors: {
            blank: "shouldn't be blank"
          }
        }
      }
    )

    errors = Zee::Model::Errors.new(nil)
    errors.add(:name, :blank)
    actual = {}
    expected = {name: ["shouldn't be blank"]}

    errors.each {|attr, list| actual[attr] = list }

    assert_equal expected, actual
  end

  test "uses attribute error translation" do
    store_translations(
      :en,
      zee: {
        model: {
          errors: {
            blank: "shouldn't be blank",
            user: {
              name: {
                blank: "is required"
              }
            }
          }
        }
      }
    )

    model = Class.new do
      def self.naming
        @naming ||= Zee::Naming::Name.new("User")
      end
    end

    errors = Zee::Model::Errors.new(model.new)
    errors.add(:name, :blank)
    actual = {}
    expected = {name: ["is required"]}

    errors.each {|attr, list| actual[attr] = list }

    assert_equal expected, actual
  end

  test "has errors" do
    errors = Zee::Model::Errors.new(nil)
    errors.add(:name, :blank, message: "can't be blank")

    assert errors.any?
  end

  test "is empty" do
    errors = Zee::Model::Errors.new(nil)

    assert_empty errors
  end

  test "returns full messages" do
    store_translations(
      :en,
      zee: {
        model: {
          errors: {
            blank: "is required"
          }
        }
      }
    )

    model = Class.new do
      def self.naming
        @naming ||= Zee::Naming::Name.new("User")
      end
    end

    errors = Zee::Model::Errors.new(model.new)
    errors.add(:name, :blank)
    expected = ["name is required"]

    assert_equal expected, errors.full_messages
  end

  test "returns full messages with custom attribute translation" do
    store_translations(
      :en,
      zee: {
        model: {
          attributes: {
            user: {
              name: "full name"
            }
          },
          errors: {
            blank: "is required"
          }
        }
      }
    )

    model = Class.new do
      def self.naming
        @naming ||= Zee::Naming::Name.new("User")
      end
    end

    errors = Zee::Model::Errors.new(model.new)
    errors.add(:name, :blank)
    expected = ["full name is required"]

    assert_equal expected, errors.full_messages
  end

  test "returns full messages with custom placeholder pattern" do
    store_translations(
      :en,
      zee: {
        model: {
          errors: {
            full_message: "%{attribute}: %{message}",
            blank: "is required"
          }
        }
      }
    )

    model = Class.new do
      def self.naming
        @naming ||= Zee::Naming::Name.new("User")
      end
    end

    errors = Zee::Model::Errors.new(model.new)
    errors.add(:name, :blank)
    expected = ["name: is required"]

    assert_equal expected, errors.full_messages
  end
end
