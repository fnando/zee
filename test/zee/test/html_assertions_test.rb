# frozen_string_literal: true

require "test_helper"

class HTMLAssertionsTest < Minitest::Test
  include Zee::Test::HTMLAssertions

  test "finds element and matches text by string" do
    html = "<div>Hello, World!</div>"

    assert_tag html, "div", text: "Hello, World!"
  end

  test "finds element and matches text by regex" do
    html = "<div>Hello, World!</div>"

    assert_tag html, "div", text: /hello/i
  end

  test "fails when count differs" do
    html = "<div>Hello, World!</div>"

    error = assert_raises(Minitest::Assertion) do
      assert_tag html, "div", count: 2
    end

    assert_includes error.message,
                    "Expected to find 2 tag(s) with selector \"div\", but " \
                    "found 1."
  end

  test "fails when text doesn't match string" do
    html = "<div>Hello, World!</div>"

    error = assert_raises(Minitest::Assertion) do
      assert_tag html, "div", text: "hello"
    end

    assert_includes error.message,
                    "Expected: \"hello\"\n  Actual: \"Hello, World!\""
  end

  test "fails when text doesn't match regexp" do
    html = "<div>Hello, World!</div>"

    error = assert_raises(Minitest::Assertion) do
      assert_tag html, "div", text: /hello/
    end

    assert_includes error.message,
                    "Expected /hello/ to match \"Hello, World!\"."
  end
end
