# frozen_string_literal: true

module Zee
  class Test < Minitest::Test
    # This test class includes [rack-test](https://github.com/rack/rack-test)
    # helper methods, and points the current app to `Zee.app`.
    #
    # @example
    #   class LoginTest < Zee::Test::Request
    #     test "renders form" do
    #       get "/login"
    #
    #       assert last_response.ok?
    #       assert_selector last_response.body,
    #                       "form[action='/login'][method=post]"
    #     end
    #   end
    class Request < Test
      include Rack::Test::Methods
      include Test::Assertions::HTML

      # Set the current app for [rack-test](https://github.com/rack/rack-test).
      # @return [Zee::App]
      def app
        Zee.app
      end

      # Set the default host that will be used by rack-test.
      def default_host
        "localhost"
      end
    end
  end
end
