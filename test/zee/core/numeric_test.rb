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

  test "returns number of seconds" do
    assert_equal 1, 1.second
    assert_equal 2, 2.seconds

    assert_equal 60, 1.minute
    assert_equal 120, 2.minutes

    assert_equal 3600, 1.hour
    assert_equal 7200, 2.hours

    assert_equal 86_400, 1.day
    assert_equal 172_800, 2.days

    assert_equal 86_400 * 7, 1.week
    assert_equal 86_400 * 14, 2.weeks

    assert_equal 2_629_746, 1.month
    assert_equal 2_629_746 * 2, 2.months

    assert_equal 31_556_952, 1.year
    assert_equal 31_556_952 * 2, 2.years

    assert_in_delta(174.0, 2.9.minutes)
  end
end
