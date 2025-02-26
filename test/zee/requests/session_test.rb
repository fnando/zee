# frozen_string_literal: true

require "test_helper"

class SessionTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Zee.app
  end

  test "sets and reads session" do
    post "/session"
    get "/session"

    assert_includes last_response.body, "1234"
    assert last_response.ok?
  end

  test "deletes session" do
    post "/session"
    delete "/session"
    get "/session"

    assert last_response.ok?
    assert_includes last_response.body, ""
  end
end
