# frozen_string_literal: true

require "test_helper"

class ResponseTest < Minitest::Test
  test "sets status" do
    response = Zee::Response.new
    response.status(200)

    assert_equal 200, response.status
  end

  test "sets status from symbol" do
    response = Zee::Response.new
    response.status(:ok)

    assert_equal 200, response.status
  end

  test "sets status using writer" do
    response = Zee::Response.new
    response.status = :ok

    assert_equal 200, response.status
  end

  test "unsets status" do
    response = Zee::Response.new
    response.status = :ok
    response.status = nil

    assert_nil response.status
  end

  test "resets status" do
    response = Zee::Response.new
    response.status = :ok
    response.body = "hello"
    response.headers[:content_type] = "text/html"
    response.reset

    assert_nil response.status
    assert_nil response.body
    assert_empty response.headers.to_h
  end
end
