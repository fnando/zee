# frozen_string_literal: true

require "test_helper"

class NumericTest < Minitest::Test
  using Zee::Core::Numeric

  test "formats duration" do
    assert_equal "1s", 1.duration
    assert_equal "10.5s", 10.5.duration

    assert_equal "100ms", 0.1.duration
    assert_equal "150ms", 0.15.duration

    assert_equal "100μs", 0.0001.duration
    assert_equal "150μs", 0.00015.duration

    assert_equal "100ns", 0.0000001.duration
    assert_equal "150ns", 0.00000015.duration
  end
end
