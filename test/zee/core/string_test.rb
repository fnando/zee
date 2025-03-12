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

  test "#dasherize" do
    assert_equal "user", "User".dasherize
    assert_equal "user-tag", "user_tag".dasherize
  end

  test "#camelcase" do
    assert_equal "User", "user".camelize
    assert_equal "UserTag", "user_tag".camelize
    assert_equal "Module::User", "module/user".camelize
    assert_equal "Module::UserTag", "module/user_tag".camelize

    assert_equal "user", "user".camelize(:lower)
    assert_equal "userTag", "user_tag".camelize(:lower)
    assert_equal "module::User", "module/user".camelize(:lower)
    assert_equal "module::UserTag", "module/user_tag".camelize(:lower)

    error = assert_raises(ArgumentError) { "user".camelize(:invalid) }
    assert_equal "invalid option: :invalid", error.message
  end

  test "#humanize" do
    assert_equal "Name", "name".humanize
    assert_equal "Full name", "full_name".humanize
    assert_equal "User", "user_id".humanize
    assert_equal "User", "_user".humanize
    assert_equal "User id", "user_id".humanize(keep_id_suffix: true)
  end
end
