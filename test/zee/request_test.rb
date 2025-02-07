# frozen_string_literal: true

require "test_helper"

class RequestTest < Minitest::Test
  test "returns subdomain" do
    request = Zee::Request.new("HTTP_HOST" => "foo.example.com")

    assert_equal "foo", request.subdomain
  end
end
