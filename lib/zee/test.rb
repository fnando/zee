# frozen_string_literal: true

gem "minitest"
require "minitest"

module Zee
  # This is a base class for all tests.
  # It sets up the test environment and provides helper methods.
  #
  # Also see <https://github.com/fnando/minitest-utils>, which includes a nicer
  # reporter, helper methods to define tests, setup and teardown steps, and
  # more!
  #
  # @example
  #   class MyTests < Zee::Test
  #     def test_truth
  #       assert true
  #     end
  #   end
  class Test < Minitest::Test
  end
end
