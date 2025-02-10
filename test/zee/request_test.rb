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
end
