# frozen_string_literal: true

require "test_helper"

class HeadersTest < Minitest::Test
  test "sets normalized header name" do
    headers = Zee::Headers.new
    headers[:content_type] = "text/html"

    assert_equal "text/html", headers[:content_type]
    assert_equal %w[content-type], headers.to_h.keys
  end
end
