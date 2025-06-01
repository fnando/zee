# frozen_string_literal: true

require "capybara/dsl"
require "capybara/minitest"

module Zee
  class Test < Minitest::Test
    # This test class includes setups
    # [Capybara](https://github.com/teamcapybara/capybara) and adds some helper
    # methods.
    #
    # By default it will use `:chrome_headless` driver by calling. To switch
    # to the rack-test driver, you can use
    # `Capybara.current_driver = :rack_test`.
    #
    # You need the following gems on your Gemfile:
    #
    # - [`capybara`](https://rubygems.org/gems/capybara)
    # - [`selenium-webdriver`](https://rubygems.org/gems/selenium-webdriver)
    #
    # When running the tests, make sure the server is running on the default
    # port `11100`. If you run `zee test`, a server will automatically start
    # when system tests are detected.
    #
    # To make assertions against elements on the page, you can use the methods
    # provided by [Capybara](https://www.rubydoc.info/gems/capybara/Capybara/Minitest/Assertions).
    #
    # > [!WARNING]
    # > The {Test::Assertions::HTML} module has a different API and it's not
    # > included by default.
    #
    # @example
    #   class LoginTest < Zee::Test::System
    #     test "renders form" do
    #       visit "/login"
    #
    #       assert_equal "/login", current_path
    #     end
    #   end
    class System < Test
      include Capybara::DSL
      include Capybara::Minitest::Assertions
      include Assertions::HTMLHelpers
      include CapybaraHelpers

      require "selenium-webdriver"

      # Register headless Chrome driver for Capybara
      Capybara.register_driver :chrome_headless do |app|
        options = Selenium::WebDriver::Chrome::Options.new
        options.add_argument("--headless")
        options.add_argument("--disable-gpu")
        options.add_argument("--window-size=1280,800")
        options.add_preference(:download,
                               prompt_for_download: false,
                               default_directory: "tmp/downloads")
        options.add_option("goog:loggingPrefs", {browser: "ALL"})

        options.add_preference(:browser,
                               set_download_behavior: {behavior: "allow"})

        Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
      end

      setup do
        port = ENV["CAPYBARA_SERVER_PORT"].to_i
        Capybara.current_driver = Capybara.javascript_driver
        Capybara.reset_sessions!
        Capybara.default_host = "http://127.0.0.1:#{port}"
        Capybara.app_host = "http://127.0.0.1:#{port}"

        Zee.app
           .config
           .set(:session_options, domain: "127.0.0.1", secure: false)
        routes.default_url_options[:host] = "127.0.0.1"
        routes.default_url_options[:port] = port
      end

      setup do
        if defined?(::Mail)
          ::Mail.defaults { delivery_method :test }
          ::Mail::TestMailer.deliveries.clear
        end
      end

      teardown do
        if failures.any?
          test_case_name = Zee.app.config.inflector.underscore(self.class.name)

          path = Zee.app
                    .root
                    .join("tmp/screenshots")
                    .join(test_case_name.delete_prefix("system/"))
                    .join("#{name}.png")
          path.dirname.mkpath
          save_screenshot(path) # rubocop:disable Lint/Debugger
        end
      end

      # The app routes so you can use the helper methods.
      #
      # @example
      #   routes.root_url
      def routes
        @routes ||= Object.new.extend(Zee.app.routes.helpers)
      end

      # Return `console.log` calls from the browser.
      def console_logs
        page.driver.browser.logs.get(:browser)
      end
    end
  end
end
