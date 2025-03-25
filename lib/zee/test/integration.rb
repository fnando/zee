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
    #       assert_selector last_response.body,
    #                       "form[action='/login'][method=post]"
    #     end
    #   end
    class Integration < Test
      include Rack::Test::Methods
      include Test::Assertions::HTML

      setup do
        routes.default_url_options[:host] = "localhost"
        routes.default_url_options[:port] = nil
      end

      setup do
        if defined?(::Mail)
          ::Mail.defaults { delivery_method :test }
          ::Mail::TestMailer.deliveries.clear
        end
      end

      # @api private
      # This is required by rack-test. The default host is `example.org`.
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
