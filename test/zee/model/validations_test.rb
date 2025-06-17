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
      validates_presence_of :name, if: :condition?

      private def condition?
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
      validates_presence_of :name, if: :condition?

      private def condition?
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
      validates_presence_of :name, unless: :condition?

      private def condition?
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
      validates_presence_of :name, unless: :condition?

      private def condition?
        true
      end
    end

    model = model_class.new(name: nil)

    assert model.valid?
  end

  test "validates using method" do
    model_class = Class.new(Zee::Model) do
      attribute :username
      validate :validate_username

      private def validate_username
        errors.add(:username, :invalid, message: "is not a valid username")
      end
    end

    model = model_class.new

    refute model.valid?
    assert_includes model.errors[:username], "is not a valid username"
  end

  test "validates using object" do
    username_validator = proc do |model|
      model.errors.add(:username, :invalid, message: "is not a valid username")
    end

    model_class = Class.new(Zee::Model) do
      attribute :username
      validate(username_validator)
    end

    model = model_class.new

    refute model.valid?
    assert_includes model.errors[:username], "is not a valid username"
  end

  test "validates using block" do
    model_class = Class.new(Zee::Model) do
      attribute :username
      validate do |model|
        model.errors.add(
          :username,
          :invalid,
          message: "is not a valid username"
        )
      end
    end

    model = model_class.new

    refute model.valid?
    assert_includes model.errors[:username], "is not a valid username"
  end

  test "fails when no validator is provided" do
    model_class = Class.new(Zee::Model) do
      attribute :username
    end

    error = assert_raises(ArgumentError) do
      model_class.validate
    end

    assert_equal "either a validator or a block must be provided", error.message
  end

  test "uses custom validator" do
    plugin = Module.new do
      def self.validate(model, attribute, options)
        default_message = "is not a valid email"
        email_re = /\A[\w.-]+@[a-z0-9-]+(\.[a-z0-9-]+)+\z/i
        value = model[attribute].to_s

        return if value.match?(email_re)

        message = model.errors.build_error_message(:email, attribute) ||
                  options[:message] ||
                  default_message

        model.errors.add(attribute, :email, message:)
      end

      def validates_email(*names, **options)
        validations << Zee::Model::Validations::Validator.new(
          Zee::Model::Validations::Email, names, options
        )
      end
    end

    Zee::Model::Validations.const_set(:Email, plugin)

    Zee::Model.extend(plugin)
    model_class = Class.new(Zee::Model) do
      attribute :email
      validates_email :email
    end
    model = model_class.new(email: "invalid_email")

    refute model.valid?
  end
end
