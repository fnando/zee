# frozen_string_literal: true

require "test_helper"

module Requests
  class PagesTest < Zee::Test::Request
    test "renders home page" do
      get "/"

      assert_equal 200, last_response.status
      assert_selector last_response.body,
                      "li:nth-child(1)",
                      text: /Zee version:/
    end
  end
end
