# frozen_string_literal: true

require "test_helper"

class HelloTest < Minitest::Test
  test "loads test helper" do
    assert TEST_HELPER_LOADED
  end
end
