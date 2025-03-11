# frozen_string_literal: true

require "capybara/dsl"
require "capybara/minitest"

module Zee
  class Test < Minitest::Test
    # This test class includes setups
    # [Capybara](https://github.com/teamcapybara/capybara) and adds some helper
    # methods.
    #
    # By default, it uses `:rack_test` as the driver. You can switch to the
    # `:chrome_headless` driver by calling `use_javascript!`.
    #
    # You need the following gems on your Gemfile:
    #
    # - [`capybara`](https://rubygems.org/gems/capybara)
    # - [`selenium-webdriver`](https://rubygems.org/gems/selenium-webdriver)
    # - [`rack-test`](https://rubygems.org/gems/rack-test)
    #
    # When running the tests, make sure the server is running on the default
    # port `11100`. If you run `zee test`, a server will automatically start
    # when integration tests are detected.
    #
    # To make assertions against elements on the page, you can use the methods
    # provided by [Capybara](https://www.rubydoc.info/gems/capybara/Capybara/Minitest/Assertions).
    #
    # > [!WARNING]
    # > The {Test::Assertions::HTML} module has a different API and it's not
    # > included by default.
    #
    # @example
    #   class LoginTest < Zee::Test::Integration
    #     use_javascript! # Switch to the `:chrome_headless` driver
    #
    #     test "renders form" do
    #       visit "/login"
    #
    #       assert_equal "/login", current_path
    #     end
    #   end
    class Integration < Test
      include Capybara::DSL
      include Capybara::Minitest::Assertions

      Capybara.register_driver :rack_test do
        Capybara::RackTest::Driver.new(Zee.app)
      end

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

      Capybara.default_driver = :rack_test
      Capybara.javascript_driver = :chrome_headless

      setup do
        Capybara.current_driver = Capybara.default_driver
        Capybara.reset_sessions!
        Capybara.default_host = "http://localhost:11100"
        Capybara.app_host = "http://localhost:11100"
        Zee.app
           .config
           .set(:session_options, domain: default_host, secure: false)
      end

      # Switch to the `:chrome_headless` driver.
      def self.use_javascript!
        setup { use_javascript! }
      end

      # Set the default host that will be used by Capybara.
      def default_host
        "localhost"
      end

      # Switch to the `:chrome_headless` driver.
      # Can be used with `setup { use_javascript! }`.
      def use_javascript!
        Capybara.current_driver = Capybara.javascript_driver
      end

      # Return `console.log` calls from the browser.
      def console_logs
        page.driver.browser.logs.get(:browser)
      end
    end
  end
end
