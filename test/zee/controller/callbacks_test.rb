# frozen_string_literal: true

require "test_helper"

class CallbacksTest < Minitest::Test
  def build
    app = Zee::App.new { root "test/fixtures/templates" }

    {
      app:,
      request: Zee::Request.new("rack.session" => {}),
      response: Zee::Response.new
    }
  end

  test "runs before action callback using block" do
    controller_class = Class.new(Zee::Controller) do
      before_action { calls << 1 }
      before_action { calls << 2 }

      def show
        render text: ""
      end

      def calls
        @calls ||= []
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: :show)
    controller.send(:call)

    assert_equal [1, 2], controller.calls
  end

  test "runs before action callback using method name" do
    controller_class = Class.new(Zee::Controller) do
      before_action :hook1
      before_action :hook2

      def show
        render text: ""
      end

      def calls
        @calls ||= []
      end

      private def hook1
        calls << 1
      end

      private def hook2
        calls << 2
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: :show)
    controller.send(:call)

    assert_equal [1, 2], controller.calls
  end

  test "runs before action only for a given action" do
    controller_class = Class.new(Zee::Controller) do
      before_action(only: :show) { calls << 1 }
      before_action(only: :other) { calls << 2 }

      def show
        render text: ""
      end

      def other
        render text: ""
      end

      def calls
        @calls ||= []
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "show")
    controller.send(:call)

    assert_equal [1], controller.calls

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "other")
    controller.send(:call)

    assert_equal [2], controller.calls
  end

  test "runs before action except for a given action" do
    controller_class = Class.new(Zee::Controller) do
      before_action(except: :other) { calls << 1 }

      def show
        render text: ""
      end

      def other
        render text: ""
      end

      def calls
        @calls ||= []
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "show")
    controller.send(:call)

    assert_equal [1], controller.calls

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "other")
    controller.send(:call)

    assert_empty controller.calls
  end

  test "runs before action using lambda as :if condition" do
    controller_class = Class.new(Zee::Controller) do
      before_action(if: proc { action_name == "show" }) { calls << 1 }

      def show
        render text: ""
      end

      def other
        render text: ""
      end

      def calls
        @calls ||= []
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "show")
    controller.send(:call)

    assert_equal [1], controller.calls

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "other")
    controller.send(:call)

    assert_empty controller.calls
  end

  test "runs before action using method name as :if condition" do
    controller_class = Class.new(Zee::Controller) do
      before_action(if: :show?) { calls << 1 }

      def show
        render text: ""
      end

      def other
        render text: ""
      end

      def calls
        @calls ||= []
      end

      private def show?
        action_name == "show"
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "show")
    controller.send(:call)

    assert_equal [1], controller.calls

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "other")
    controller.send(:call)

    assert_empty controller.calls
  end

  test "runs before action using lambda as :unless condition" do
    controller_class = Class.new(Zee::Controller) do
      before_action(unless: proc { action_name == "other" }) { calls << 1 }

      def show
        render text: ""
      end

      def other
        render text: ""
      end

      def calls
        @calls ||= []
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "show")
    controller.send(:call)

    assert_equal [1], controller.calls

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "other")
    controller.send(:call)

    assert_empty controller.calls
  end

  test "runs before action using method name as :unless condition" do
    controller_class = Class.new(Zee::Controller) do
      before_action(unless: :other?) { calls << 1 }

      def show
        render text: ""
      end

      def other
        render text: ""
      end

      def calls
        @calls ||= []
      end

      private def other?
        action_name == "other"
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "show")
    controller.send(:call)

    assert_equal [1], controller.calls

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "other")
    controller.send(:call)

    assert_empty controller.calls
  end

  test "raises when passing both a method and block to before_action" do
    error = assert_raises(ArgumentError) do
      Class.new(Zee::Controller) do
        before_action(:do_something) { calls << 1 }
      end
    end
    assert_equal "cannot pass both method names and a block", error.message
  end

  test "rendering from before action prevents action from being executed" do
    controller_class = Class.new(Zee::Controller) do
      before_action { render text: "before_action" }

      def show
        render text: "action"
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "show")
    controller.send(:call)

    assert_equal "before_action", response.body
  end

  test "redirecting from before action prevents action from being executed" do
    controller_class = Class.new(Zee::Controller) do
      before_action { redirect_to "/" }

      def show
        render text: "action"
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "show")
    controller.send(:call)

    assert_equal 302, response.status
  end

  test "runs after action callback using block" do
    controller_class = Class.new(Zee::Controller) do
      after_action { calls << 1 }
      after_action { calls << 2 }

      def show
        render text: ""
      end

      def calls
        @calls ||= []
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: :show)
    controller.send(:call)

    assert_equal [1, 2], controller.calls
  end

  test "runs after action callback using method name" do
    controller_class = Class.new(Zee::Controller) do
      after_action :hook1
      after_action :hook2

      def show
        render text: ""
      end

      def calls
        @calls ||= []
      end

      private def hook1
        calls << 1
      end

      private def hook2
        calls << 2
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: :show)
    controller.send(:call)

    assert_equal [1, 2], controller.calls
  end

  test "runs after action only for a given action" do
    controller_class = Class.new(Zee::Controller) do
      after_action(only: :show) { calls << 1 }
      after_action(only: :other) { calls << 2 }

      def show
        render text: ""
      end

      def other
        render text: ""
      end

      def calls
        @calls ||= []
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "show")
    controller.send(:call)

    assert_equal [1], controller.calls

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "other")
    controller.send(:call)

    assert_equal [2], controller.calls
  end

  test "runs after action except for a given action" do
    controller_class = Class.new(Zee::Controller) do
      after_action(except: :other) { calls << 1 }

      def show
        render text: ""
      end

      def other
        render text: ""
      end

      def calls
        @calls ||= []
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "show")
    controller.send(:call)

    assert_equal [1], controller.calls

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "other")
    controller.send(:call)

    assert_empty controller.calls
  end

  test "runs after action using lambda as :if condition" do
    controller_class = Class.new(Zee::Controller) do
      after_action(if: proc { action_name == "show" }) { calls << 1 }

      def show
        render text: ""
      end

      def other
        render text: ""
      end

      def calls
        @calls ||= []
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "show")
    controller.send(:call)

    assert_equal [1], controller.calls

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "other")
    controller.send(:call)

    assert_empty controller.calls
  end

  test "runs after action using method name as :if condition" do
    controller_class = Class.new(Zee::Controller) do
      after_action(if: :show?) { calls << 1 }

      def show
        render text: ""
      end

      def other
        render text: ""
      end

      def calls
        @calls ||= []
      end

      private def show?
        action_name == "show"
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "show")
    controller.send(:call)

    assert_equal [1], controller.calls

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "other")
    controller.send(:call)

    assert_empty controller.calls
  end

  test "runs after action using lambda as :unless condition" do
    controller_class = Class.new(Zee::Controller) do
      after_action(unless: proc { action_name == "other" }) { calls << 1 }

      def show
        render text: ""
      end

      def other
        render text: ""
      end

      def calls
        @calls ||= []
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "show")
    controller.send(:call)

    assert_equal [1], controller.calls

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "other")
    controller.send(:call)

    assert_empty controller.calls
  end

  test "runs after action using method name as :unless condition" do
    controller_class = Class.new(Zee::Controller) do
      after_action(unless: :other?) { calls << 1 }

      def show
        render text: ""
      end

      def other
        render text: ""
      end

      def calls
        @calls ||= []
      end

      private def other?
        action_name == "other"
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "show")
    controller.send(:call)

    assert_equal [1], controller.calls

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "other")
    controller.send(:call)

    assert_empty controller.calls
  end

  test "raises when passing both a method and block to after_action" do
    error = assert_raises(ArgumentError) do
      Class.new(Zee::Controller) do
        after_action(:do_something) { calls << 1 }
      end
    end
    assert_equal "cannot pass both method names and a block", error.message
  end

  test "inherits callbacks" do
    base_class = Class.new(Zee::Controller) do
      before_action { calls << 1 }
      before_action { calls << 2 }

      def calls
        @calls ||= []
      end
    end

    controller_class = Class.new(base_class) do
      def show
        render text: ""
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: :show)
    controller.send(:call)

    assert_equal [1, 2], controller.calls
  end

  test "skip before action" do
    controller_class = Class.new(Zee::Controller) do
      before_action :hook
      skip_before_action :hook

      def show
        render text: ""
      end

      def calls
        @calls ||= []
      end

      private def hook
        calls << 1
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: :show)
    controller.send(:call)

    assert_empty controller.calls
  end

  test "skip before action with condition" do
    controller_class = Class.new(Zee::Controller) do
      before_action :hook
      skip_before_action :hook, only: :other

      def show
        render text: ""
      end

      def other
        render text: ""
      end

      def calls
        @calls ||= []
      end

      private def hook
        calls << 1
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: :show)
    controller.send(:call)

    assert_equal [1], controller.calls

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: :other)
    controller.send(:call)

    assert_empty controller.calls
  end

  test "skip after action" do
    controller_class = Class.new(Zee::Controller) do
      after_action :hook
      skip_after_action :hook

      def show
        render text: ""
      end

      def calls
        @calls ||= []
      end

      private def hook
        calls << 1
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: :show)
    controller.send(:call)

    assert_empty controller.calls
  end

  test "skip after action with condition" do
    controller_class = Class.new(Zee::Controller) do
      after_action :hook
      skip_after_action :hook, only: :other

      def show
        render text: ""
      end

      def other
        render text: ""
      end

      def calls
        @calls ||= []
      end

      private def hook
        calls << 1
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: :show)
    controller.send(:call)

    assert_equal [1], controller.calls

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: :other)
    controller.send(:call)

    assert_empty controller.calls
  end

  test "runs both before and after actions" do
    controller_class = Class.new(Zee::Controller) do
      after_action { calls << :after }
      before_action { calls << :before }

      def show
        render text: ""
      end

      def calls
        @calls ||= []
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: :show)
    controller.send(:call)

    assert_equal %i[before after], controller.calls
  end

  test "instruments halted actions" do
    Zee.app.config.set(:enable_instrumentation, true)

    controller_class = Class.new(Zee::Controller) do
      before_action { redirect_to "/" }

      def show
        render text: "action"
      end
    end

    build => {request:, response:}
    controller = controller_class.new(request:, response:, action_name: "show")
    controller.send(:call)

    store = RequestStore.store[:instrumentation][:request]
    expected_instrumentation = {
      name: :request,
      duration: nil,
      args: {
        scope: :before_action,
        source: "test/zee/controller/callbacks_test.rb:712",
        redirected_to: "/"
      }
    }

    assert_equal 1, store.size
    assert_equal expected_instrumentation, store.first
  end
end
