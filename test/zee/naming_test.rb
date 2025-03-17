# frozen_string_literal: true

require "test_helper"

class NamingTest < Minitest::Test
  test "returns singular" do
    assert_equal "user", Zee::Naming.new("User").singular
    assert_equal "models/user", Zee::Naming.new("Models::User").singular
    assert_equal "user",
                 Zee::Naming.new("Models::User", prefix: "Models").singular
  end

  test "returns plural" do
    assert_equal "users", Zee::Naming.new("User").plural
    assert_equal "models/users", Zee::Naming.new("Models::User").plural
    assert_equal "users",
                 Zee::Naming.new("Models::User", prefix: "Models").plural
  end
end
