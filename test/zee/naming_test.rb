# frozen_string_literal: true

require "test_helper"

class NamingTest < Minitest::Test
  test "returns singular" do
    assert_equal "user", Zee::Naming::Name.new("User").singular
    assert_equal "models/user", Zee::Naming::Name.new("Models::User").singular
    assert_equal "user",
                 Zee::Naming::Name.new("Models::User", prefix: "Models")
                                  .singular
    assert_equal "admin/user",
                 Zee::Naming::Name.new("Models::Admin::User", prefix: "Models")
                                  .singular
    assert_equal "user",
                 Zee::Naming::Name.new("Models::Admin::User",
                                       prefix: "Models::Admin").singular

    assert_equal "user", Zee::Naming::Name.new("Users").singular
    assert_equal "models/user", Zee::Naming::Name.new("Models::Users").singular
    assert_equal "user",
                 Zee::Naming::Name.new("Models::Users", prefix: "Models")
                                  .singular
    assert_equal "admin/user",
                 Zee::Naming::Name.new("Models::Admin::Users", prefix: "Models")
                                  .singular
    assert_equal "user",
                 Zee::Naming::Name.new("Models::Admin::Users",
                                       prefix: "Models::Admin").singular
  end

  test "returns plural" do
    assert_equal "users", Zee::Naming::Name.new("User").plural
    assert_equal "models/users", Zee::Naming::Name.new("Models::User").plural
    assert_equal "users",
                 Zee::Naming::Name.new("Models::User", prefix: "Models").plural
    assert_equal "admin/users",
                 Zee::Naming::Name.new("Models::Admin::User", prefix: "Models")
                                  .plural
    assert_equal "users",
                 Zee::Naming::Name.new("Models::Admin::User",
                                       prefix: "Models::Admin").plural
  end

  test "returns underscore name" do
    assert_equal "user", Zee::Naming::Name.new("User").underscore
    assert_equal "models/user",
                 Zee::Naming::Name.new("Models::User").underscore
    assert_equal "user",
                 Zee::Naming::Name.new("Models::User", prefix: "Models")
                                  .underscore
    assert_equal "admin/user",
                 Zee::Naming::Name.new("Models::Admin::User", prefix: "Models")
                                  .underscore
    assert_equal "user",
                 Zee::Naming::Name.new("Models::Admin::User",
                                       prefix: "Models::Admin").underscore
  end

  test "extends class" do
    klass = Class.new do
      def self.name
        "User"
      end

      extend Zee::Naming
    end

    assert_equal "user", klass.naming.singular
    assert_equal "users", klass.naming.plural
  end
end
