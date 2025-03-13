# frozen_string_literal: true

require "test_helper"

class ErrorHandlingTest < Minitest::Test
  def build
    app = Zee::App.new { root "test/fixtures/templates" }
    app.config.set(:handle_errors, true)
    Zee.app = app

    {
      app:,
      request: Zee::Request.new("rack.session" => {}),
      response: Zee::Response.new
    }
  end

  test "rescues from runtime error using method" do
    controller_class = Class.new(Zee::Controller) do
      rescue_from RuntimeError, with: :handle_error

      def show
        raise "nope"
      end

      private def handle_error(error)
        render text: "rescued from #{error.class} => #{error.message}",
               status: 500
      end
    end

    build => {request:, response:}
    controller = controller_class.new(
      request:,
      response:,
      controller_name: "application",
      action_name: :show
    )
    controller.send(:call)

    assert_equal 500, response.status
    assert_includes response.body, "rescued from RuntimeError => nope"
  end

  test "rescues from runtime error using block" do
    controller_class = Class.new(Zee::Controller) do
      rescue_from RuntimeError do |error|
        render text: "rescued from #{error.class} => #{error.message}",
               status: 500
      end

      def show
        raise "nope"
      end
    end

    build => {request:, response:}
    controller = controller_class.new(
      request:,
      response:,
      controller_name: "application",
      action_name: :show
    )
    controller.send(:call)

    assert_equal 500, response.status
    assert_includes response.body, "rescued from RuntimeError => nope"
  end

  test "renders default error when handling is enabled and error not caught" do
    controller_class = Class.new(Zee::Controller) do
      def show
        raise "nope"
      end
    end

    build => {request:, response:}
    controller = controller_class.new(
      request:,
      response:,
      controller_name: "application",
      action_name: :show
    )
    controller.send(:call)

    assert_equal 500, response.status
    assert_includes response.body, "500 Internal Server Error"
  end
end
