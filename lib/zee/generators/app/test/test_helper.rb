# frozen_string_literal: true

ENV["ZEE_ENV"] = "test"

require "zee/simplecov"
SimpleCov.start(:zee)

require_relative "../config/environment"

module Zee
  class Test < Minitest::Test
    setup do
      DatabaseCleaner[:sequel].strategy = :truncation
      DatabaseCleaner[:sequel].clean
    end
  end
end
