# frozen_string_literal: true

ENV["ZEE_ENV"] = "test"

require "zee/simplecov"
SimpleCov.start(:zee)

require "zee/rspec"
require_relative "../config/environment"
require "rspec"

RSpec.configure do |config|
  config.before(:each) do
    DatabaseCleaner[:sequel].strategy = :truncation
    DatabaseCleaner[:sequel].clean
  end
end
