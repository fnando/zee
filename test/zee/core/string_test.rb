# frozen_string_literal: true

require "test_helper"

class StringTest < Minitest::Test
  using Zee::Core::String

  test "#underscore" do
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

  test "#camelcase" do
    assert_equal "User", "user".camelize
    assert_equal "UserTag", "user_tag".camelize
    assert_equal "Module::User", "module/user".camelize
    assert_equal "Module::UserTag", "module/user_tag".camelize
  end

  test "#humanize" do
    assert_equal "Name", "name".humanize
    assert_equal "Full name", "full_name".humanize
    assert_equal "User", "user_id".humanize
    assert_equal "User id", "user_id".humanize(keep_id_suffix: true)
  end

  test "#blank?" do
    assert "".blank?
    assert "   ".blank?
    assert "\r\n\t   ".blank?
    assert "\u00a0".blank?

    refute "hello".blank?
    refute "  hello ".blank?
    refute "\r\n\t hello  ".blank?
  end

  test "#present?" do
    refute "".present?
    refute "   ".present?
    refute "\r\n\t   ".present?
    refute "\u00a0".present?

    assert "hello".present?
    assert "  hello ".present?
    assert "\r\n\t hello  ".present?
  end
end
