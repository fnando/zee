# frozen_string_literal: true

module Zee
  class Test < Minitest::Test
    # This test class includes [rack-test](https://github.com/rack/rack-test)
    # helper methods, and points the current app to `Zee.app`.
    #
    # @example
    #   class LoginTest < Zee::Test::Integration
    #     test "renders form" do
    #       get "/login"
    #
    #       assert last_response.ok?
    #       assert_html last_response.body,
    #                       "form[action='/login'][method=post]"
    #     end
    #   end
    class Integration < Test
      include Rack::Test::Methods
      include Test::Assertions::HTML
      include Capybara::DSL
      include Capybara::Minitest::Assertions
      include CapybaraHelpers

      setup do
        Capybara.current_driver = Capybara.default_driver
        Capybara.reset_sessions!
        Capybara.default_host = "http://127.0.0.1"
        Capybara.app_host = "http://127.0.0.1"
        routes.default_url_options[:host] = "127.0.0.1"
        routes.default_url_options[:port] = ENV["CAPYBARA_SERVER_PORT"]
      end

      setup do
        if defined?(::Mail)
          ::Mail.defaults { delivery_method :test }
          ::Mail::TestMailer.deliveries.clear
        end
      end

      # @api private
      # This is required by rack-test. The default host is `example.org`, so
      # let's replace it with the host defined in the route.
      def default_host
        routes.default_url_options[:host]
      end

      # Set the current app for [rack-test](https://github.com/rack/rack-test).
      # @return [Zee::App]
      def app
        Zee.app
      end

      # The app routes so you can use the helper methods.
      #
      # @example
      #   routes.root_url
      def routes
        @routes ||= Object.new.extend(Zee.app.routes.helpers)
      end
    end
  end
end
