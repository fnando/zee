# frozen_string_literal: true

ENV["ZEE_ENV"] = "test"

require "zee/simplecov"
SimpleCov.start(:zee)

require_relative "../config/environment"
require "minitest/utils"
require "minitest/autorun"
