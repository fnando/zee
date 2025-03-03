# frozen_string_literal: true

require "test_helper"

class RequestTest < Minitest::Test
  test "returns subdomain" do
    request = Zee::Request.new("HTTP_HOST" => "foo.example.com")

    assert_equal "foo", request.subdomain
  end

  test "normalizes trailing slashes" do
    request = Zee::Request.new("PATH_INFO" => "/posts/")

    assert_equal "/posts", request.path_with_no_trailing_slash
  end

  test "returns origin" do
    assert_equal "https://example.com",
                 Zee::Request.new("HTTP_ORIGIN" => "https://example.com").origin
  end

  test "detects xhr" do
    refute Zee::Request.new({}).xhr?
    refute Zee::Request.new("HTTP_X_REQUESTED_WITH" => "something").xhr?
    assert Zee::Request.new("HTTP_X_REQUESTED_WITH" => "XMLHttpRequest").xhr?
    assert Zee::Request.new("HTTP_X_REQUESTED_WITH" => "xmlhttprequest").xhr?
  end
end
