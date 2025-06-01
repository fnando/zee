# frozen_string_literal: true

require "test_helper"

class HTMLTest < Minitest::Test
  include Zee::Test::Assertions::HTML

  test "finds element and matches text by string" do
    html = "<div>Hello, World!</div>"

    assert_html html, "div", text: "Hello, World!"
  end

  test "finds element and matches text by regex" do
    html = "<div>Hello, World!</div>"

    assert_html html, "div", text: /hello/i
  end

  test "fails when count differs" do
    html = "<div>Hello, World!</div>"

    error = assert_raises(Minitest::Assertion) do
      assert_html html, "div", count: 2
    end

    assert_includes error.message,
                    "Expected to find exactly 2 tag(s) with selector " \
                    "\"div\", but found 1\n\n<div>Hello, World!</div>\n"
  end

  test "fails when text doesn't match string" do
    html = "<div>Hello, World!</div>"

    error = assert_raises(Minitest::Assertion) do
      assert_html html, "div", text: "hello"
    end

    assert_includes error.message,
                    "Expected to find at least 1 tag(s) with selector " \
                    "\"div\" with text matching \"hello\", but found 0\n\n" \
                    "<div>Hello, World!</div>\n"
  end

  test "fails when text doesn't match regexp" do
    html = "<div>Hello, World!</div>"

    error = assert_raises(Minitest::Assertion) do
      assert_html html, "div", text: /hello/
    end

    assert_includes error.message,
                    "Expected to find at least 1 tag(s) with selector " \
                    "\"div\" with text matching /hello/, but found 0\n\n" \
                    "<div>Hello, World!</div>\n"
  end
end
