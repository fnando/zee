# frozen_string_literal: true

gem "minitest"
gem "minitest-utils"

require "minitest"
require "minitest/utils"

module Zee
  # This is a base class for all tests.
  # It sets up the test environment and provides helper methods.
  #
  # @example
  #   class MyTests < Zee::Test
  #     test "it passes" do
  #       assert true
  #     end
  #   end
  class Test < Minitest::Test
    if defined?(::Capybara)
      Capybara.default_driver = :rack_test
      Capybara.javascript_driver = :chrome_headless

      Capybara.register_driver :rack_test do
        Capybara::RackTest::Driver.new(Zee.app)
      end
    end
  end
end
