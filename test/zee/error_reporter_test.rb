# frozen_string_literal: true

require "test_helper"

class ErrorReporterTest < Minitest::Test
  test "reports error with context" do
    RequestStore[:error_context] = {user_id: 1}

    reporter = Zee::ErrorReporter.new
    error = StandardError.new
    handler = ErrorHandler.new
    reporter.subscribe(handler)

    reporter.report(error, context: {admin: true})

    assert_equal error, handler.errors.first.error
    assert_equal({admin: true, user_id: 1}, handler.errors.first.context)
  end

  test "unsubscribes from notifications" do
    reporter = Zee::ErrorReporter.new
    handler = ErrorHandler.new
    reporter.subscribe(handler)
    reporter.unsubscribe(handler)

    assert_empty reporter.handlers
  end

  test "notifies all handlers before re-raising handler errors" do
    reporter = Zee::ErrorReporter.new
    h1 = ErrorHandler.new
    h2 = ErrorHandler.new
    app_error = StandardError.new

    def h1.call(**)
      raise "nope"
    end

    reporter.subscribe(h1)
    reporter.subscribe(h2)

    error = assert_raises(RuntimeError) do
      reporter.report(app_error)
    end

    assert_equal app_error, h2.errors.first.error
    assert_equal "nope", error.message
  end
end
