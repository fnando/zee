# frozen_string_literal: true

require "dotenv"
require "rack/test"

begin
  require "capybara"
  require "capybara/rspec"
rescue LoadError
  # noop
end

Dotenv.load(".env.test")

module Zee
  # Zee has RSpec support for request and feature tests. This module includes
  # helper methods for both types of tests. It sets the default host to
  # `Zee.app.config.domain` for `type: :request`, and `"localhost"` for
  # `type: :feature`.
  #
  # For feature tests, it sets the Capybara driver to `:rack_test` by default.
  # If the test has the metadata `js: true`, it will switch to the
  # `:chrome_headless` driver and also starts a Puma server on port `11100`.
  #
  # @example Feature specs must live under `spec/features`
  #   `File: spec/features/login_spec.rb`
  #
  #   ```ruby
  #   require "spec_helper"
  #
  #   RSpec.describe "Login" do
  #     visit "/"
  #     click_link "Log in"
  #
  #     expect(page).to have_current_path("/login")
  #   end
  #   ```
  #
  # @example Request specs must live under `spec/requests`
  #   `File: spec/requests/login_spec.rb`
  #
  #   ```ruby
  #   require "spec_helper"
  #
  #   RSpec.describe "Login" do
  #     get "/"
  #
  #     expect(last_response.status).to eq(200)
  #   end
  #   ```
  module RSpec
    module Request
      include Rack::Test::Methods

      def app
        Zee.app
      end
    end
  end
end

if defined?(Capybara)
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

    options.add_preference(:browser,
                           set_download_behavior: {behavior: "allow"})

    Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
  end

  # Register rack-test driver for Capybara
  Capybara.register_driver :rack_test do
    Capybara::RackTest::Driver.new(Zee.app)
  end

  Capybara.javascript_driver = :chrome_headless
  Capybara.default_driver = :rack_test
end

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{spec/requests}) do |metadata|
    metadata[:type] = :request
  end

  config.define_derived_metadata(file_path: %r{spec/features}) do |metadata|
    metadata[:type] = :feature
  end

  config.include(Zee::RSpec::Request, type: :request)
  config.include(Zee::RSpec::Feature, type: :feature)

  running_puma = false

  config.before(type: :feature) do |example|
    next if running_puma
    next unless example.metadata[:js]

    pid = Process.spawn(
      "bundle",
      "exec",
      "puma",
      "--environment", "test",
      "--config", "./config/puma.rb",
      "--silent",
      "--quiet",
      "--bind", "tcp://127.0.0.1:11100"
    )
    Process.detach(pid)
    puts "Integration test server: http://localhost:11100 [pid=#{pid}]"
    require "net/http"
    attempts = 0

    loop do
      attempts += 1
      uri = URI("http://localhost:11100/")

      begin
        Net::HTTP.get_response(uri)
        break
      rescue Errno::ECONNREFUSED
        if attempts == 10
          raise Thor::Error,
                set_color("ERROR: Unable to start Puma at #{uri}", :red)
        end

        sleep 0.05
      end
    end

    at_exit { Process.kill("INT", pid) }
  end

  config.before(type: :feature) do |example|
    unless defined?(Capybara)
      raise "Capybara is not loaded. Add `gem 'capybara'` to your Gemfile."
    end

    Capybara.reset_sessions!

    Capybara.current_driver = if example.metadata[:js]
                                Capybara.javascript_driver
                              else
                                Capybara.default_driver
                              end
    Capybara.default_host = "http://localhost:11100"
    Capybara.app_host = "http://localhost:11100"
    Zee.app.config.set(:session_options, domain: "localhost", secure: false)
  end
end
