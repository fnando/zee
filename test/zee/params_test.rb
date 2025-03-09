# frozen_string_literal: true

require "test_helper"

class ParamsTest < Minitest::Test
  test "accesses a key" do
    params = Zee::Params.new("a" => "1")

    assert_equal "1", params[:a]
    assert_equal "1", params["a"]
  end

  test "accesses a key when input is symbol based" do
    params = Zee::Params.new(a: "1")

    assert_equal "1", params[:a]
    assert_equal "1", params["a"]
  end

  test "accesses nested keys" do
    params = Zee::Params.new({"user" => {"name" => "john"}})

    assert_equal "john", params[:user][:name]
    assert_equal "john", params["user"]["name"]
  end

  test "fails when key is missing" do
    params = Zee::Params.new({})

    error = assert_raises(Zee::Params::ParameterMissingError) do
      params.require(:a)
    end

    assert_equal "param is missing: a", error.message
  end

  test "fails when unpermitted keys are provided" do
    params = Zee::Params.new(
      {"user" => {"name" => "john", "email" => "john@example.com"}}
    )

    error = assert_raises(Zee::Params::UnpermittedParameterError) do
      params.require(:user).permit(:username)
    end

    assert_equal "found unpermitted keys: name, email", error.message
  end

  test "accesses permitted params" do
    params = Zee::Params.new(
      {"user" => {"name" => "john", "email" => "john@example.com"}}
    )

    assert_equal "john", params.require(:user).permit(:name, :email)[:name]
  end
end
