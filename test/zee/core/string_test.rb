# frozen_string_literal: true

require "test_helper"

class StringTest < Minitest::Test
  using Zee::Core::String

  test "converts to underscore" do
    assert_equal "user", "User".underscore
    assert_equal "user_tag", "UserTag".underscore
    assert_equal "api", "API".underscore
    assert_equal "user_api", "UserAPI".underscore
    assert_equal "html_encoder", "HTMLEncoder".underscore
    assert_equal "module/user", "Module::User".underscore
    assert_equal "module/user_tag", "Module::UserTag".underscore
    assert_equal "module/api", "Module::API".underscore
    assert_equal "module/user_api", "Module::UserAPI".underscore
    assert_equal "module/html_encoder", "Module::HTMLEncoder".underscore
  end
end
