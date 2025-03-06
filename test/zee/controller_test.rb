# frozen_string_literal: true

require "test_helper"

class ControllerTest < Minitest::Test
  let(:app) { Zee::App.new { root "test/fixtures/templates" } }
  let(:response) { Zee::Response.new }
  let(:request) { Zee::Request.new("rack.session" => {}) }

  setup do
    app.config.set(:logger, NULL_LOGGER)
    Zee.app = app
  end

  test "returns session" do
    controller = Zee::Controller.new(request:, response:)

    assert_same request.session, controller.send(:session)
  end

  test "exposes variable" do
    controller_class = Class.new(Zee::Controller) do
      def show
        expose message: "Hello, World!"
        render :locals
      end

      private def say_hello(name:)
        "Hello, #{name}!"
      end
    end

    controller_class.new(request:, response:, action_name: "show").send(:call)

    assert_includes response.body, "Hello, World!"
  end

  test "exposes helper method" do
    controller_class = Class.new(Zee::Controller) do
      def show
        expose :say_hello
        render :helper
      end

      private def say_hello(name:)
        "Hello, #{name}!"
      end
    end

    controller_class.new(request:, response:, action_name: "show").send(:call)

    assert_includes response.body, "Hello, John!"
    assert_includes response.body, "Hello, Mary!"
  end

  test "exposes helper method with instance variable" do
    controller_class = Class.new(Zee::Controller) do
      def show
        expose :current_user, :user_logged_in?
        render :helper_with_ivar
      end

      private def current_user
        @current_user ||= {name: "John"}
      end

      private def user_logged_in?
        current_user != nil
      end
    end

    controller_class.new(request:, response:, action_name: "show").send(:call)

    assert_includes response.body, "Hello, John!"
    refute_includes response.body, "You're not logged in."
  end

  test "prevents exposting public helper methods" do
    controller_class = Class.new(Zee::Controller) do
      def show
        expose :current_user
      end

      def current_user
        @current_user ||= {name: "John"}
      end
    end

    error = assert_raises Zee::Controller::UnsafeHelperError do
      controller_class.new(request:, response:, action_name: "show").send(:call)
    end

    assert_equal ":current_user must be a private method", error.message
  end

  test "exposes helper method for all controller methods" do
    controller_class = Class.new(Zee::Controller) do
      expose :say_hello

      def show
        render :helper
      end

      private def say_hello(name:)
        "Hello, #{name}!"
      end
    end

    controller_class.new(request:, response:, action_name: "show").send(:call)

    assert_includes response.body, "Hello, John!"
    assert_includes response.body, "Hello, Mary!"
  end
end
