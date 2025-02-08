# frozen_string_literal: true

require "simplecov"
SimpleCov.start

require "bundler/setup"
require "zee"
require "zee/cli"
require "rack/test"

require "minitest/utils"
require "minitest/autorun"

Dir["#{__dir__}/support/**/*.rb"].each do |file|
  require file
end

module Minitest
  class Test
    setup { FileUtils.rm_rf("tmp") }
    setup { FileUtils.mkdir("tmp") }
    teardown { FileUtils.rm_rf("tmp") }
  end
end
