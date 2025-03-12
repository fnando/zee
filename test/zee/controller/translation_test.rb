# frozen_string_literal: true

require "test_helper"

module Controller
  class TranslationTest < Minitest::Test
    let(:response) { Zee::Response.new }
    let(:request) { Zee::Request.new("rack.session" => {}) }

    test "localizes text" do
      now = Time.now
      Time.stubs(:now).returns(now)
      store_translations(:en, time: {formats: {short: "%Y-%m-%d"}})

      controller_class = Class.new(Zee::Controller) do
        def show
          render text: l(Time.now, format: :short)
        end
      end

      controller_class.new(request:, response:, action_name: "show").send(:call)

      assert_includes response.body, now.strftime("%Y-%m-%d")
    end

    test "returns translation as it is" do
      controller_class = Class.new(Zee::Controller) do
        def show
          render text: t("hello")
        end
      end

      store_translations :en, hello: "Hello there!"
      controller_class.new(request:, response:, action_name: "show").send(:call)

      assert_includes response.body, "Hello there!"
    end

    test "returns translation scoped by controller and action" do
      controller_class = Class.new(Zee::Controller) do
        def show
          render text: t(".hello")
        end
      end

      store_translations :en, {pages: {show: {hello: "Hello there!"}}}
      controller_class.new(
        request:, response:, controller_name: "pages", action_name: "show"
      ).send(:call)

      assert_includes response.body, "Hello there!"
    end

    test "returns translation scoped by controller and action with namespace" do
      controller_class = Class.new(Zee::Controller) do
        def show
          render text: t(".hello")
        end
      end

      store_translations :en,
                         {admin: {dashboard: {show: {hello: "Hello there!"}}}}
      controller_class.new(
        request:,
        response:,
        controller_name: "admin/dashboard",
        action_name: "show"
      ).send(:call)

      assert_includes response.body, "Hello there!"
    end
  end
end
