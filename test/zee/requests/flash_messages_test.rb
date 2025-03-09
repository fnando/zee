# frozen_string_literal: true

require "test_helper"

class FlashMessagesTest < Zee::Test::Request
  test "sets message" do
    post "/messages"
    follow_redirect!

    assert last_response.ok?
    assert_includes last_response.body, "Message created."

    get "/messages"

    refute_includes last_response.body, "Message created."
  end
end
