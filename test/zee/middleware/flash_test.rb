# frozen_string_literal: true

require "test_helper"

module Middleware
  class FlashTest < Minitest::Test
    let(:app) { ->(_env) { [200, {}, []] } }
    let(:session) { {} }
    let(:env) { Rack::MockRequest.env_for("/", "rack.session" => session) }

    test "discards messages that must be discarded" do
      session[:flash] = {
        messages: {notice: "NOTICE", error: "ERROR"},
        discard: [:notice]
      }

      Zee::Middleware::Flash.new(app).call(env)

      assert_equal({error: "ERROR"}, session[:flash][:messages])
    end

    test "marks messages to be discarded next" do
      session[:flash] = {
        messages: {notice: "NOTICE", error: "ERROR"},
        discard: [:notice]
      }

      Zee::Middleware::Flash.new(app).call(env)

      assert_equal [:error], session[:flash][:discard]
    end

    test "skips middleware if session is not present" do
      status, _ =
        Zee::Middleware::Flash.new(app).call(env.delete("rack.session"))

      assert_equal 200, status
    end
  end
end
