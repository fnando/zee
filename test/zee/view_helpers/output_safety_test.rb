# frozen_string_literal: true

require "test_helper"

class OutputSafetyTest < Minitest::Test
  let(:helpers) do
    mod = Module.new do
      attr_accessor :request

      include Zee::ViewHelpers::OutputSafety
    end

    Object.new.extend(mod)
  end

  test "returns raw string" do
    assert_equal "<script>", helpers.raw("<script>").to_s
  end

  test "returns buffer as raw string" do
    buffer = Zee::SafeBuffer.new.concat("<script>")

    assert_equal "<script>", helpers.raw(buffer).to_s
  end

  test "escapes json" do
    assert_equal "\\u003cscript\\u003e", helpers.escape_json("<script>").to_s
  end

  test "escapes html" do
    assert_equal "&lt;script&gt;", helpers.escape_html("<script>").to_s
  end
end
