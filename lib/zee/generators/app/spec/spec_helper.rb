# frozen_string_literal: true

ENV["ZEE_ENV"] = "test"

require "zee/simplecov"
SimpleCov.start(:zee)

require "zee/rspec"
require_relative "../config/environment"
require "rspec"
