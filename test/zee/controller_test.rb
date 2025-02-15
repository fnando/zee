# frozen_string_literal: true

require "test_helper"

class ControllerTest < Minitest::Test
  let(:response) { Zee::Response.new }
  let(:request) { Zee::Request.new({"rack.session" => {}}) }

  test "returns params" do
    controller = Zee::Controller.new(request:, response:)

    assert_same request.params, controller.params
  end

  test "returns session" do
    controller = Zee::Controller.new(request:, response:)

    assert_same request.session, controller.session
  end
end
