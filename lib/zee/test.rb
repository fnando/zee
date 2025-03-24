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
    # Sets up email delivery as test.
    setup do
      ::Mail.defaults { delivery_method :test }
      ::Mail::TestMailer.deliveries.clear
    rescue LoadError
      # no `mail` gem available
    end
  end
end
