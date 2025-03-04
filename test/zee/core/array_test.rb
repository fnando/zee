# frozen_string_literal: true

require "test_helper"

class ArrayTest < Minitest::Test
  using Zee::Core::Array

  test "#to_sentence with `and` connector" do
    assert_equal "", [].to_sentence
    assert_equal "a", ["a"].to_sentence
    assert_equal "a and b", %w[a b].to_sentence
    assert_equal "a, b, and c", %w[a b c].to_sentence
    assert_equal "a, b, c, and d", %w[a b c d].to_sentence
    assert_equal "a, b, c, d, and e", %w[a b c d e].to_sentence
    assert_equal "a, b, c, d, e, and f", %w[a b c d e f].to_sentence
  end

  test "#to_sentence with `or` connector" do
    assert_equal "", [].to_sentence(scope: :or)
    assert_equal "a", ["a"].to_sentence(scope: :or)
    assert_equal "a or b", %w[a b].to_sentence(scope: :or)
    assert_equal "a, b, or c", %w[a b c].to_sentence(scope: :or)
    assert_equal "a, b, c, or d", %w[a b c d].to_sentence(scope: :or)
    assert_equal "a, b, c, d, or e", %w[a b c d e].to_sentence(scope: :or)
    assert_equal "a, b, c, d, e, or f", %w[a b c d e f].to_sentence(scope: :or)
  end
end
