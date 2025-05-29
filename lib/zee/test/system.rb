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
        port = ENV["CAPYBARA_SERVER_PORT"].to_i
        Capybara.current_driver = Capybara.javascript_driver
        Capybara.reset_sessions!
        Capybara.default_host = "http://127.0.0.1:#{port}"
        Capybara.app_host = "http://127.0.0.1:#{port}"

        Zee.app
           .config
           .set(:session_options, domain: "localhost", secure: false)
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

      # Click email link for the given text. This will extract links from your
      # HTML part of the email. If no HTML is defined, then an exception will be
      # raised.
      #
      # The email will that will be used is the last one. To click a link on a
      # specific message, pass it as a second argument.
      #
      # @example
      #   click_email_link "Log in now"
      #   click_email_link "Log in now", Zee::Test::Mailer.deliveries.first
      #
      # @param text [String, Regexp] The text to click.
      # @param mail [Zee::Mailer::Message] The mail to use.
      def click_email_link(text, mail = Zee::Test::Mailer.deliveries.last)
        text = Regexp.escape(text) unless text.is_a?(Regexp)

        if mail.nil?
          raise Minitest::Assertion,
                "Expected an email to have been delivered; got nil"
        end

        if text.to_s.empty?
          raise Minitest::Assertion,
                "Expected text to be a non-empty String or a Regexp; " \
                "got #{text.inspect}"
        end

        html = Nokogiri::HTML(mail.html_part.decoded)
        link = html.css("a[href]").find { _1.text.strip.match?(text) }

        unless link
          raise Minitest::Assertion,
                "Couldn't find link #{text.inspect} in email\n\n" \
                "#{format_html(html)}"
        end

        visit link[:href]
      end
    end
  end
end
