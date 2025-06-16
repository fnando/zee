# frozen_string_literal: true

require "test_helper"

class ControllerTest < Minitest::Test
  let(:app) { Zee::App.new { root "test/fixtures/templates" } }
  let(:response) { Zee::Response.new }
  let(:request) { Zee::Request.new("rack.session" => {}) }

  setup do
    app.config.set(:logger, logger)
    Zee.app = app
  end

  test "returns session" do
    controller = Zee::Controller.new(request:, response:)

    assert_same request.session, controller.send(:session)
  end

  test "exposes variable" do
    controller_class = Class.new(Zee::Controller) do
      def show
        @message = "Hello, World!"
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
      helper_method :say_hello

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

  test "exposes helper method with instance variable" do
    controller_class = Class.new(Zee::Controller) do
      helper_method :current_user, :user_logged_in?

      def show
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
      helper_method :current_user

      def show
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
      helper_method :say_hello

      def show
        render :helper
      end

      private def say_hello(name:)
        "Hello, #{name}!"
      end
    end

    controller_class.new(
      request:,
      response:,
      action_name: "show"
    ).send(:call)

    assert_includes response.body, "Hello, John!"
    assert_includes response.body, "Hello, Mary!"
  end

  test "raises error when action is missing" do
    controller_class = Class.new(Zee::Controller) do
      # noop
    end

    error = assert_raises(Zee::Controller::MissingActionError) do
      controller_class.new(
        request:,
        response:,
        controller_name: "application",
        action_name: "show"
      ).send(:call)
    end
    assert_equal "action application#show is not defined.", error.message
  end

  test "raises error when rendering twice" do
    controller_class = Class.new(Zee::Controller) do
      def show
        render :show
        render :show
      end
    end

    error = assert_raises(Zee::Controller::DoubleRenderError) do
      controller_class.new(
        request:,
        response:,
        controller_name: "application",
        action_name: "show"
      ).send(:call)
    end
    assert_includes error.message, "Render/redirect called multiple times"
  end

  test "raises error when redirecting twice" do
    controller_class = Class.new(Zee::Controller) do
      def show
        redirect_to "/"
        redirect_to "/"
      end
    end

    error = assert_raises(Zee::Controller::DoubleRenderError) do
      controller_class.new(
        request:,
        response:,
        controller_name: "application",
        action_name: "show"
      ).send(:call)
    end
    assert_includes error.message, "Render/redirect called multiple times"
  end

  test "raises error when redirecting after rendering" do
    controller_class = Class.new(Zee::Controller) do
      def show
        render :show
        redirect_to "/"
      end
    end

    error = assert_raises(Zee::Controller::DoubleRenderError) do
      controller_class.new(
        request:,
        response:,
        controller_name: "application",
        action_name: "show"
      ).send(:call)
    end
    assert_includes error.message, "Render/redirect called multiple times"
  end

  test "raises error when rendering after redirecting" do
    controller_class = Class.new(Zee::Controller) do
      def show
        redirect_to "/"
        render :show
      end
    end

    error = assert_raises(Zee::Controller::DoubleRenderError) do
      controller_class.new(
        request:,
        response:,
        controller_name: "application",
        action_name: "show"
      ).send(:call)
    end
    assert_includes error.message, "Render/redirect called multiple times"
  end

  test "raises error when double rendering from rescue from" do
    controller_class = Class.new(Zee::Controller) do
      rescue_from RuntimeError do
        redirect_to "/somewhere-else"
      end

      def show
        redirect_to "/"
        raise "nope"
      end
    end

    error = assert_raises(Zee::Controller::DoubleRenderError) do
      controller_class.new(
        request:,
        response:,
        controller_name: "application",
        action_name: "show"
      ).send(:call)
    end
    assert_includes error.message, "Render/redirect called multiple times"
  end

  %i[notice alert info error].each do |key|
    test "sets #{key} flash message for redirect" do
      controller_class = Class.new(Zee::Controller) do
        define_method :redirect do
          redirect_to "/", key => key.to_s.upcase
        end
      end

      controller_class.new(
        request:,
        response:,
        action_name: "redirect"
      ).send(:call)

      assert_equal key.to_s.upcase, request.session[:flash][:messages][key]
    end
  end

  test "reports errors from actions" do
    Zee.app.config.set(:handle_errors, true)
    handler = ErrorHandler.new
    Zee.error << handler

    controller_class = Class.new(Zee::Controller) do
      def self.name
        "Controllers::MyController"
      end

      def show
        raise "nope"
      end
    end

    controller_class.new(
      request:,
      response:,
      controller_name: "application",
      action_name: "show"
    ).send(:call)

    assert_instance_of RuntimeError, handler.errors.first.error
    assert_equal "nope", handler.errors.first.error.message
    assert_equal "show", handler.errors.first.context[:action_name]
    assert_equal "application", handler.errors.first.context[:controller_name]
    assert_equal "Controllers::MyController",
                 handler.errors.first.context[:controller_class]
  end

  test "reports errors from before actions" do
    Zee.app.config.set(:handle_errors, true)
    handler = ErrorHandler.new
    Zee.error << handler

    controller_class = Class.new(Zee::Controller) do
      before_action { raise "nope" }

      def show
      end
    end

    controller_class.new(
      request:,
      response:,
      controller_name: "application",
      action_name: "show"
    ).send(:call)

    assert_instance_of RuntimeError, handler.errors.first.error
    assert_equal "nope", handler.errors.first.error.message
  end

  test "reports errors from after actions" do
    Zee.app.config.set(:handle_errors, true)
    handler = ErrorHandler.new
    Zee.error << handler

    controller_class = Class.new(Zee::Controller) do
      after_action { raise "nope" }

      def show
      end
    end

    controller_class.new(
      request:,
      response:,
      controller_name: "application",
      action_name: "show"
    ).send(:call)

    assert_instance_of RuntimeError, handler.errors.first.error
    assert_equal "nope", handler.errors.first.error.message
  end

  test "reports errors from rescue from" do
    Zee.app.config.set(:handle_errors, true)
    handler = ErrorHandler.new
    Zee.error << handler

    controller_class = Class.new(Zee::Controller) do
      rescue_from(Exception) { raise "nope" }

      def show
        raise "not here"
      end
    end

    controller_class.new(
      request:,
      response:,
      controller_name: "application",
      action_name: "show"
    ).send(:call)

    assert_instance_of RuntimeError, handler.errors[0].error
    assert_equal "not here", handler.errors[0].error.message
    assert_instance_of RuntimeError, handler.errors[1].error
    assert_equal "nope", handler.errors[1].error.message
  end

  test "reports all errors from rescue from" do
    Zee.app.config.set(:handle_errors, true)
    h1 = ErrorHandler.new
    h2 = ErrorHandler.new
    Zee.error << h1
    Zee.error << h2

    controller_class = Class.new(Zee::Controller) do
      rescue_from(Exception) { raise "nope" }
      rescue_from(Exception) { raise "nope again" }

      def show
        raise "not here"
      end
    end

    controller_class.new(
      request:,
      response:,
      controller_name: "application",
      action_name: "show"
    ).send(:call)

    assert_instance_of RuntimeError, h1.errors[0].error
    assert_equal "not here", h1.errors[0].error.message

    assert_instance_of RuntimeError, h1.errors[1].error
    assert_equal "nope again", h1.errors[1].error.message

    assert_instance_of RuntimeError, h1.errors[2].error
    assert_equal "nope", h1.errors[2].error.message
  end

  test "renders using specified content type" do
    controller_class = Class.new(Zee::Controller) do
      def show
        render body: "<svg></svg>", content_type: "image/svg+xml"
      end
    end

    controller_class.new(
      request:,
      response:,
      controller_name: "application",
      action_name: "show"
    ).send(:call)

    assert_equal "<svg></svg>", response.body
    assert_equal "image/svg+xml", response.headers["content-type"]
  end
end
