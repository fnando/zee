# frozen_string_literal: true

ENV["ZEE_ENV"] ||= "test"

require "simplecov"
SimpleCov.start

require "minitest/autorun"
