# frozen_string_literal: true

require "test_helper"

class ParameterFilterTest < Minitest::Test
  test "filters string keys" do
    params = {"password" => "secret", "password_confirmation" => "secret"}
    params = Zee::ParameterFilter.new(["passw"]).filter(params)

    assert_equal "[filtered]", params["password"]
    assert_equal "[filtered]", params["password_confirmation"]
  end

  test "filters symbol keys" do
    params = {password: "secret", password_confirmation: "secret"}
    params = Zee::ParameterFilter.new(["passw"]).filter(params)

    assert_equal "[filtered]", params[:password]
    assert_equal "[filtered]", params[:password_confirmation]
  end

  test "filters nested hash" do
    params = {user: {password: "secret", password_confirmation: "secret"}}
    params = Zee::ParameterFilter.new(["passw"]).filter(params)

    assert_equal "[filtered]", params[:user][:password]
    assert_equal "[filtered]", params[:user][:password_confirmation]
  end

  test "filters with array" do
    params = {
      users: [
        {
          user: {
            password: "secret",
            password_confirmation: "secret"
          }
        }
      ]
    }
    params = Zee::ParameterFilter.new(["passw"]).filter(params)

    assert_equal "[filtered]", params[:users].first[:user][:password]
    assert_equal "[filtered]",
                 params[:users].first[:user][:password_confirmation]
  end

  test "filters mixed" do
    params = {
      list: [
        {
          user: [
            {password: "secret"},
            {password_confirmation: "secret"},
            {email: "1@example.com"}
          ]
        },
        {
          user: [
            {password: "secret"},
            {password_confirmation: "secret"},
            {email: "2@example.com"}
          ]
        }
      ]
    }
    params = Zee::ParameterFilter.new(["passw"]).filter(params)
    users = params[:list]

    assert_equal "[filtered]", users[0][:user][0][:password]
    assert_equal "[filtered]", users[0][:user][1][:password_confirmation]
    assert_equal "1@example.com", users[0][:user][2][:email]

    assert_equal "[filtered]", users[1][:user][0][:password]
    assert_equal "[filtered]", users[1][:user][1][:password_confirmation]
    assert_equal "2@example.com", users[1][:user][2][:email]
  end

  test "filters using custom mask" do
    params = {"password" => "secret", "password_confirmation" => "secret"}
    params = Zee::ParameterFilter.new(["passw"])
                                 .filter(params, mask: "[secret]")

    assert_equal "[secret]", params["password"]
    assert_equal "[secret]", params["password_confirmation"]
  end
end
