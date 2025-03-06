# frozen_string_literal: true

require "capybara/dsl"
require "capybara/minitest"

module Zee
  class Test < Minitest::Test
    class Integration < Test
      include Capybara::DSL
      include Capybara::Minitest::Assertions

      setup do
        Capybara.register_driver :rack_test do
          Capybara::RackTest::Driver.new(Zee.app)
        end

        Capybara.reset_sessions!
        Capybara.current_driver = :rack_test
        Capybara.default_host = "http://localhost"
        Zee.app.config.set(:session_options, domain: "localhost", secure: false)
      end
    end
  end
end
