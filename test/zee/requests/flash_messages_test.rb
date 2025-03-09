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

  test "keeps specified message between actions" do
    post "/messages/set-keep"

    assert last_response.redirection?
    assert_equal "/messages/keep", last_response.location
    assert last_response.redirection?

    follow_redirect! # from /messages/set-keep -> /messages/keep
    follow_redirect! # from /messages/keep -> /messages

    assert_equal "/messages", last_request.path

    assert last_response.ok?
    assert_includes last_response.body, "[NOTICE] Message updated."
    refute_includes last_response.body, "[INFO] Message updated."

    get "/messages"

    refute_includes last_response.body, "Message updated."
  end

  test "keeps all messages between actions" do
    post "/messages/set-keep-all"
    puts last_response.body

    assert last_response.redirection?
    assert_equal "/messages/keep-all", last_response.location
    assert last_response.redirection?

    follow_redirect! # from /messages/set-keep-all -> /messages/keep-all
    follow_redirect! # from /messages/keep-all -> /messages

    assert_equal "/messages", last_request.path

    assert last_response.ok?
    assert_includes last_response.body, "[NOTICE] Message removed."
    assert_includes last_response.body, "[INFO] Message removed."

    get "/messages"

    refute_includes last_response.body, "Message removed."
  end
end
